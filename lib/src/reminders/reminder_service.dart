import 'dart:async';
import 'dart:math';
import 'dart:ui' show Locale;

import 'package:flutter/foundation.dart';
import 'package:timezone/timezone.dart' as tz;

import '../../l10n/app_localizations.dart';
import '../question_format/models.dart';
import '../questions/question_set_repository.dart';
import '../quiz/progress.dart';
import '../quiz/progress_repository.dart';
import '../quiz/selection.dart';
import 'planner.dart';
import 'reminder_notifications.dart';
import 'reminder_settings.dart';
import 'reminder_store.dart';

/// Plans and schedules the reminders (architecture § Reminders): keeps the
/// next [plannedReminderCount] reminders scheduled, each with a pre-picked
/// question, and re-plans whenever it is asked to.
abstract interface class Reminders {
  /// Whether this platform has reminders at all (Android only).
  bool get supported;

  /// Taps on reminders while the app runs, and the one that started it.
  ReminderLaunches get launches;

  /// Re-plans from fresh data: called when the home page opens, after a
  /// quiz, and when the active set or the reminder settings change.
  Future<void> sync({
    required String uid,
    required QuestionSetInfo set,
    required ReminderSettings settings,
  });

  /// Re-plans from the snapshot on the phone (daily background job).
  Future<void> replanFromStore();

  /// Shows a reminder right now (button in the settings).
  Future<bool> sendTest({required String uid, required QuestionSetInfo set});

  Future<bool> requestPermission();

  Future<bool> notificationsEnabled();

  /// Cancels everything and forgets the snapshot (sign-out).
  Future<void> clear();
}

/// The reminder that was tapped, waiting for the home page to open it.
class ReminderLaunches extends ChangeNotifier {
  ReminderLaunch? _pending;

  ReminderLaunch? get pending => _pending;

  void add(ReminderLaunch launch) {
    _pending = launch;
    notifyListeners();
  }

  /// Returns the pending launch and clears it.
  ReminderLaunch? take() {
    final launch = _pending;
    _pending = null;
    return launch;
  }
}

/// [Reminders] for platforms without them (web).
class NoReminders implements Reminders {
  @override
  bool get supported => false;

  @override
  final launches = ReminderLaunches();

  @override
  Future<void> sync({
    required String uid,
    required QuestionSetInfo set,
    required ReminderSettings settings,
  }) async {}

  @override
  Future<void> replanFromStore() async {}

  @override
  Future<bool> sendTest({
    required String uid,
    required QuestionSetInfo set,
  }) async =>
      false;

  @override
  Future<bool> requestPermission() async => false;

  @override
  Future<bool> notificationsEnabled() async => false;

  @override
  Future<void> clear() async {}
}

class ReminderService implements Reminders {
  ReminderService({
    required this.store,
    required this.notifications,
    this.questionSets,
    this.progress,
    required this.location,
    AppLocalizations? l10n,
    DateTime Function()? clock,
    Random? random,
  })  : _l10n = l10n ?? lookupAppLocalizations(const Locale('hu')),
        _clock = clock ?? DateTime.now,
        _random = random ?? Random() {
    _picker = QuestionPicker(random: _random);
  }

  final ReminderStore store;
  final ReminderNotifications notifications;

  /// Not needed by the background job, which works from the snapshot.
  final QuestionSetRepository? questionSets;
  final ProgressRepository? progress;
  final tz.Location location;
  final AppLocalizations _l10n;
  final DateTime Function() _clock;
  final Random _random;
  late final QuestionPicker _picker;

  @override
  final launches = ReminderLaunches();

  /// Runs the jobs one after the other, so overlapping requests do not
  /// schedule twice.
  Future<void> _queue = Future.value();

  Future<T> _serial<T>(Future<T> Function() job) {
    final result = _queue.then((_) => job());
    _queue = result.then((_) {}, onError: (_) {});
    return result;
  }

  @override
  bool get supported => true;

  /// Hooks up taps; call once at app start.
  Future<void> start() async {
    await notifications.initialize(onTap: launches.add, onAnswer: answer);
    final launch = await notifications.launchedBy();
    if (launch != null) launches.add(launch);
  }

  @override
  Future<void> sync({
    required String uid,
    required QuestionSetInfo set,
    required ReminderSettings settings,
  }) =>
      _serial(() async {
        try {
          await _flushAnswers(uid);
          if (!settings.enabled) {
            await notifications.cancelScheduled();
            await store.clear();
            return;
          }
          final snapshot = await _freshSnapshot(uid, set, settings);
          await store.save(snapshot);
          await _schedule(snapshot);
        } on Object catch (error) {
          debugPrint('Reminder sync failed: $error');
        }
      });

  @override
  Future<void> replanFromStore() => _serial(() async {
        final snapshot = await store.load();
        if (snapshot == null || !snapshot.settings.enabled) {
          await notifications.cancelScheduled();
          return;
        }
        await _schedule(snapshot);
      });

  @override
  Future<bool> sendTest({
    required String uid,
    required QuestionSetInfo set,
  }) =>
      _serial(() async {
        try {
          final previous = await store.load();
          final snapshot = await _freshSnapshot(
            uid,
            set,
            previous?.settings ?? const ReminderSettings(),
          );
          final key = _picker.pick(
            [for (final question in snapshot.questions) question.key],
            snapshot.progress,
          );
          if (key == null) return false;
          final now = tz.TZDateTime.from(_clock(), location);
          var reminder = PlannedReminder(now, key);
          if (snapshot.settings.mode == ReminderMode.trueFalse) {
            reminder = reminder.withStatement(
              pickStatement(snapshot.question(key)!, _random),
            );
          }
          await notifications.showNow(
            _notice(snapshot, reminder, scheduled: false),
          );
          return true;
        } on Object catch (error) {
          debugPrint('Test reminder failed: $error');
          return false;
        }
      });

  @override
  Future<bool> requestPermission() => notifications.requestPermission();

  @override
  Future<bool> notificationsEnabled() => notifications.areEnabled();

  @override
  Future<void> clear() => _serial(() async {
        await notifications.cancelScheduled();
        await store.clear();
      });

  /// Igaz or Hamis pressed in a notification – in the background isolate
  /// (without Firebase) or, rarely, while the app runs. Updates the progress
  /// on the phone, queues the answer for Firestore, shows the result and the
  /// next statement in the same notification, and re-plans.
  Future<void> answer(ReminderAnswer answer) => _serial(() async {
        try {
          final launch = answer.launch;
          final snapshot = await store.load();
          final question = snapshot?.question(launch.key);
          final statement = launch.statement;
          if (snapshot == null ||
              snapshot.setId != launch.setId ||
              question == null ||
              statement == null) {
            return;
          }
          final correct = answer.saidTrue == (statement == correctStatement);
          final at = _clock();
          final records = {
            ...snapshot.progress,
            launch.key: (snapshot.progress[launch.key] ?? const ItemProgress())
                .recordAnswer(correct: correct, at: at),
          };
          final updated = snapshot.copyWith(progress: records);
          await store.save(updated);
          await store.queueAnswer(
            QueuedAnswer(
              uid: snapshot.uid,
              setId: snapshot.setId,
              key: launch.key,
              correct: correct,
              at: at,
            ),
          );
          // While the app runs, Firestore is at hand.
          await _flushAnswers(snapshot.uid);

          final nextKey = _picker.pick(
            [for (final question in snapshot.questions) question.key],
            records,
            recent: [launch.key],
            exclude: {launch.key},
          );
          final next = nextKey == null
              ? null
              : PlannedReminder(
                  tz.TZDateTime.from(at, location),
                  nextKey,
                  statement: pickStatement(updated.question(nextKey)!, _random),
                );
          await notifications.showNow(
            _result(
              updated,
              question,
              statement: statement,
              correct: correct,
              next: next,
              id: answer.notificationId,
            ),
          );
          if (updated.settings.enabled) await _schedule(updated);
        } on Object catch (error) {
          debugPrint('Answer from notification failed: $error');
        }
      });

  /// Writes the answers given in notifications to Firestore: each is
  /// replayed on the stored record in order (counters add up, the box moves),
  /// and a later `lastAt` from the app is kept. Needs the repositories, so
  /// it does nothing in the background isolate.
  Future<void> _flushAnswers(String uid) async {
    final repository = progress;
    if (repository == null) return;
    final answers = await store.takeAnswers(uid);
    if (answers.isEmpty) return;
    try {
      final bySet = <String, List<QueuedAnswer>>{};
      for (final answer in answers) {
        (bySet[answer.setId] ??= []).add(answer);
      }
      for (final MapEntry(key: setId, value: queued) in bySet.entries) {
        final current = await repository.load(uid, setId);
        final changed = <String, ItemProgress>{};
        for (final answer in queued) {
          final before =
              changed[answer.key] ?? current[answer.key] ?? const ItemProgress();
          changed[answer.key] = replayAnswer(before, answer);
        }
        for (final MapEntry(:key, :value) in changed.entries) {
          // Offline the write completes only on reconnection; do not wait.
          unawaited(repository.save(uid, setId, key, value));
        }
      }
    } on Object {
      for (final answer in answers) {
        await store.queueAnswer(answer);
      }
      rethrow;
    }
  }

  /// Questions come from the stored snapshot while the set is unchanged
  /// (saves 149 reads); progress is always read again.
  Future<ReminderSnapshot> _freshSnapshot(
    String uid,
    QuestionSetInfo set,
    ReminderSettings settings,
  ) async {
    final previous = await store.load();
    final version = set.importedAt?.millisecondsSinceEpoch;
    final reuse = previous != null &&
        previous.uid == uid &&
        previous.setId == set.id &&
        previous.setVersion == version &&
        previous.questions.isNotEmpty;
    final questions =
        reuse ? previous.questions : await questionSets!.loadQuestions(set.id);
    final records = await progress!.load(uid, set.id);
    return ReminderSnapshot(
      uid: uid,
      setId: set.id,
      setTitle: set.title,
      setVersion: version,
      questions: questions,
      progress: records,
      settings: settings,
    );
  }

  Future<void> _schedule(ReminderSnapshot snapshot) async {
    final plan = planFor(snapshot, tz.TZDateTime.from(_clock(), location));
    await notifications.schedule([
      for (final reminder in plan) _notice(snapshot, reminder),
    ]);
  }

  /// The reminders to schedule for [snapshot] after [now]; in true/false
  /// mode each with its statement.
  @visibleForTesting
  List<PlannedReminder> planFor(ReminderSnapshot snapshot, tz.TZDateTime now) {
    final plan = assignQuestions(
      reminderSlots(snapshot.settings.windows, now),
      [for (final question in snapshot.questions) question.key],
      snapshot.progress,
      picker: _picker,
    );
    if (snapshot.settings.mode != ReminderMode.trueFalse) return plan;
    return [
      for (final reminder in plan)
        reminder.withStatement(
          pickStatement(snapshot.question(reminder.key)!, _random),
        ),
    ];
  }

  ReminderNotice _notice(
    ReminderSnapshot snapshot,
    PlannedReminder reminder, {
    bool scheduled = true,
  }) {
    final question = snapshot.question(reminder.key);
    final statement = reminder.statement;
    final trueFalse = question != null && statement != null;
    return ReminderNotice(
      id: scheduled ? reminder.id : testNotificationId,
      // No filler text: true/false shows the statement, otherwise only the
      // title (and the prompt, if any).
      title: trueFalse ? _l10n.reminderTrueFalseTitle : _l10n.reminderTitle,
      body: trueFalse ? statementText(question, statement) : reminderBody(question),
      payload: ReminderLaunch(
        setId: snapshot.setId,
        key: reminder.key,
        statement: trueFalse ? statement : null,
      ),
      time: scheduled ? reminder.time : null,
      answerButtons: trueFalse,
    );
  }

  /// The result of an answer, and the next statement if there is one.
  ReminderNotice _result(
    ReminderSnapshot snapshot,
    Question question, {
    required int statement,
    required bool correct,
    required PlannedReminder? next,
    required int id,
  }) {
    final title =
        correct ? _l10n.reminderResultCorrect : _l10n.reminderResultWrong;
    final nextQuestion = next == null ? null : snapshot.question(next.key);
    final lines = [
      // Unless „Igaz” was rightly said to the correct statement, show it.
      if (!(correct && statement == correctStatement))
        _l10n.reminderCorrectStatement(question.correct.text),
      if (next != null && nextQuestion != null)
        _l10n.reminderNextStatement(
          statementText(nextQuestion, next.statement!),
        ),
    ];
    return ReminderNotice(
      id: id,
      title: title,
      body: lines.isEmpty ? null : lines.join('\n\n'),
      payload: ReminderLaunch(
        setId: snapshot.setId,
        key: next?.key ?? question.key,
        statement: next?.statement,
      ),
      answerButtons: next != null && nextQuestion != null,
      quiet: true,
    );
  }
}

/// True/false mode: the correct option or one of the wrong ones, half and
/// half, so „Igaz” and „Hamis” are equally likely right.
int pickStatement(Question question, Random random) =>
    question.wrong.isEmpty || random.nextBool()
        ? correctStatement
        : random.nextInt(question.wrong.length);

/// The text of [statement] of [question].
String statementText(Question question, int statement) =>
    statement == correctStatement || statement >= question.wrong.length
        ? question.correct.text
        : question.wrong[statement].text;

/// [before] after a queued [answer]: counters and box as if answered now,
/// but a later `lastAt` (from an answer given in the app) is kept.
ItemProgress replayAnswer(ItemProgress before, QueuedAnswer answer) {
  final after = before.recordAnswer(correct: answer.correct, at: answer.at);
  final lastAt = before.lastAt;
  if (lastAt == null || !lastAt.isAfter(answer.at)) return after;
  return ItemProgress(
    box: after.box,
    seen: after.seen,
    correct: after.correct,
    wrong: after.wrong,
    lastAt: lastAt,
    skippable: after.skippable,
  );
}

/// Outside the range of [reminderIdFor] for any realistic date.
const testNotificationId = 1;

/// The notification text: the question's prompt if it has one, otherwise
/// nothing – not the subject, which in some questions gives the answer away
/// (e.g. „dojo”).
String? reminderBody(Question? question) {
  final prompt = question?.prompt;
  return prompt != null && prompt.isNotEmpty ? prompt : null;
}

/// The default reminder time zone, after the time-zone data is loaded.
tz.Location reminderLocation() => tz.getLocation(reminderTimeZone);
