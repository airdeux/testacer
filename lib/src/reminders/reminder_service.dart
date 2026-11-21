import 'dart:async';
import 'dart:math';
import 'dart:ui' show Locale;

import 'package:flutter/foundation.dart';
import 'package:timezone/timezone.dart' as tz;

import '../../l10n/app_localizations.dart';
import '../question_format/models.dart';
import '../questions/question_set_repository.dart';
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
        _picker = QuestionPicker(random: random);

  final ReminderStore store;
  final ReminderNotifications notifications;

  /// Not needed by the background job, which works from the snapshot.
  final QuestionSetRepository? questionSets;
  final ProgressRepository? progress;
  final tz.Location location;
  final AppLocalizations _l10n;
  final DateTime Function() _clock;
  final QuestionPicker _picker;

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
    await notifications.initialize(onTap: launches.add);
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
          await notifications.showNow(
            _notice(snapshot, PlannedReminder(now, key), scheduled: false),
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

  /// The reminders to schedule for [snapshot] after [now].
  @visibleForTesting
  List<PlannedReminder> planFor(ReminderSnapshot snapshot, tz.TZDateTime now) =>
      assignQuestions(
        reminderSlots(snapshot.settings.windows, now),
        [for (final question in snapshot.questions) question.key],
        snapshot.progress,
        picker: _picker,
      );

  ReminderNotice _notice(
    ReminderSnapshot snapshot,
    PlannedReminder reminder, {
    bool scheduled = true,
  }) {
    final question = snapshot.question(reminder.key);
    return ReminderNotice(
      id: scheduled ? reminder.id : testNotificationId,
      title: _l10n.reminderTitle,
      body: reminderBody(_l10n, question),
      payload: ReminderLaunch(setId: snapshot.setId, key: reminder.key),
      time: scheduled ? reminder.time : null,
    );
  }
}

/// Outside the range of [reminderIdFor] for any realistic date.
const testNotificationId = 1;

/// The notification text: the question's prompt, or its subject, so the
/// answer is not given away.
String reminderBody(AppLocalizations l10n, Question? question) {
  final prompt = question?.prompt;
  if (prompt != null && prompt.isNotEmpty) return prompt;
  final subjects = question?.correct.markedTexts(MarkKind.subject) ?? const [];
  if (subjects.isEmpty) return l10n.reminderBodyPlain;
  return l10n.reminderBodySubject(subjects.take(2).join(', '));
}

/// The default reminder time zone, after the time-zone data is loaded.
tz.Location reminderLocation() => tz.getLocation(reminderTimeZone);
