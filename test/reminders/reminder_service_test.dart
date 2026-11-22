import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:testacer/src/question_format/models.dart';
import 'package:testacer/src/questions/question_set_repository.dart';
import 'package:testacer/src/quiz/progress.dart';
import 'package:testacer/src/reminders/planner.dart';
import 'package:testacer/src/reminders/reminder_notifications.dart';
import 'package:testacer/src/reminders/reminder_service.dart';
import 'package:testacer/src/reminders/reminder_settings.dart';
import 'package:testacer/src/reminders/reminder_store.dart';
import 'package:timezone/data/latest_10y.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import '../support/fakes.dart';

class MemoryReminderStore implements ReminderStore {
  ReminderSnapshot? snapshot;

  @override
  Future<ReminderSnapshot?> load() async => snapshot;

  @override
  Future<void> save(ReminderSnapshot snapshot) async =>
      // Through JSON, as on the phone.
      this.snapshot = ReminderSnapshot.fromJson(snapshot.toJson());

  @override
  Future<void> clear() async => snapshot = null;

  final answers = <QueuedAnswer>[];

  @override
  Future<void> queueAnswer(QueuedAnswer answer) async => answers.add(answer);

  @override
  Future<List<QueuedAnswer>> takeAnswers(String uid) async {
    final mine = answers.where((a) => a.uid == uid).toList();
    answers.removeWhere((a) => a.uid == uid);
    return mine;
  }
}

/// Counts question loads.
class CountingQuestionSets extends FakeQuestionSetRepository {
  int loads = 0;

  @override
  Future<List<Question>> loadQuestions(String setId) {
    loads++;
    return super.loadQuestions(setId);
  }
}

void main() {
  setUpAll(tz_data.initializeTimeZones);

  late MemoryReminderStore store;
  late FakeReminderNotifications notifications;
  late CountingQuestionSets questionSets;
  late FakeProgressRepository progress;
  late QuestionSetInfo set;
  late ReminderService service;
  // Saturday 2026-11-21 15:49 in Budapest.
  final now = DateTime.utc(2026, 11, 21, 14, 49);

  const on = ReminderSettings(enabled: true);

  setUp(() {
    store = MemoryReminderStore();
    notifications = FakeReminderNotifications();
    questionSets = CountingQuestionSets();
    progress = FakeProgressRepository();
    set = questionSets.add('set1', 'Gyakorló teszt', sampleQuestions());
    service = ReminderService(
      store: store,
      notifications: notifications,
      questionSets: questionSets,
      progress: progress,
      location: tz.getLocation(reminderTimeZone),
      l10n: hu,
      clock: () => now,
      random: Random(7),
    );
  });

  test('schedules the next 48 reminders with questions of the set', () async {
    await service.sync(uid: 'u1', set: set, settings: on);

    final scheduled = notifications.scheduled;
    expect(scheduled, hasLength(48));
    final first = scheduled.first;
    expect(first.time!.hour, 16);
    expect(first.time!.minute, 0);
    expect(first.title, hu.reminderTitle);
    final keys = sampleQuestions().map((q) => q.key).toSet();
    for (final notice in scheduled) {
      expect(notice.payload.setId, 'set1');
      expect(keys, contains(notice.payload.key));
      expect(notice.id, reminderIdFor(notice.time!));
    }
    expect(store.snapshot!.questions, hasLength(3));
  });

  test('the reminder shows only its title: nothing to give the answer away',
      () async {
    for (final question in sampleQuestions()) {
      expect(reminderBody(question), isNull);
    }
    expect(reminderBody(null), isNull);
  });

  test('skippable questions are left out', () async {
    final questions = sampleQuestions();
    progress.data['set1'] = {
      questions[0].key: const ItemProgress(skippable: true),
      questions[1].key: const ItemProgress(skippable: true),
    };
    await service.sync(uid: 'u1', set: set, settings: on);

    expect(
      notifications.scheduled.map((n) => n.payload.key).toSet(),
      {questions[2].key},
    );
  });

  test('switching off cancels everything and forgets the snapshot', () async {
    await service.sync(uid: 'u1', set: set, settings: on);
    await service.sync(uid: 'u1', set: set, settings: const ReminderSettings());

    expect(notifications.scheduled, isEmpty);
    expect(store.snapshot, isNull);
  });

  test('questions are loaded again only when the set changes', () async {
    await service.sync(uid: 'u1', set: set, settings: on);
    await service.sync(uid: 'u1', set: set, settings: on);
    expect(questionSets.loads, 1);

    final reimported = QuestionSetInfo(
      id: 'set1',
      title: 'Gyakorló teszt',
      questionCount: 3,
      importedAt: DateTime.utc(2026, 11, 22),
    );
    await service.sync(uid: 'u1', set: reimported, settings: on);
    expect(questionSets.loads, 2);

    await service.sync(uid: 'u2', set: reimported, settings: on);
    expect(questionSets.loads, 3);
  });

  test('the background job re-plans from the snapshot alone', () async {
    await service.sync(uid: 'u1', set: set, settings: on);
    notifications.scheduled.clear();

    final background = ReminderService(
      store: store,
      notifications: notifications,
      location: tz.getLocation(reminderTimeZone),
      l10n: hu,
      clock: () => now.add(const Duration(days: 1)),
    );
    await background.replanFromStore();

    expect(notifications.scheduled, hasLength(48));
    expect(notifications.scheduled.first.time!.day, 22);
  });

  test('the background job cancels when there is no snapshot', () async {
    notifications.scheduled.add(
      ReminderNotice(
        id: 1,
        title: '',
        body: '',
        payload: const ReminderLaunch(setId: 's', key: 'k'),
        time: tz.TZDateTime.now(tz.UTC),
      ),
    );
    await service.replanFromStore();
    expect(notifications.scheduled, isEmpty);
  });

  test('a test notification is shown at once', () async {
    expect(await service.sendTest(uid: 'u1', set: set), isTrue);
    expect(notifications.shown.single.id, testNotificationId);
    expect(notifications.shown.single.payload.setId, 'set1');
    expect(notifications.scheduled, isEmpty);
  });

  test('a tap, or the tap that started the app, is passed on', () async {
    notifications.launch = const ReminderLaunch(setId: 'set1', key: 'k1');
    await service.start();
    expect(service.launches.take(), const ReminderLaunch(setId: 'set1', key: 'k1'));

    notifications.onTap!(const ReminderLaunch(setId: 'set1', key: 'k2'));
    expect(service.launches.pending?.key, 'k2');
  });

  test('payloads survive encoding; foreign ones are ignored', () {
    const launch = ReminderLaunch(setId: 'set1', key: 'abc');
    expect(ReminderLaunch.decode(launch.encode()), launch);
    expect(ReminderLaunch.decode('nonsense'), isNull);
    expect(ReminderLaunch.decode(null), isNull);
  });

  test('a broken snapshot is ignored', () {
    expect(ReminderSnapshot.fromJson('{'), isNull);
    expect(ReminderSnapshot.fromJson('{"version": 2}'), isNull);
  });

  group('true/false mode', () {
    const trueFalse = ReminderSettings(
      enabled: true,
      mode: ReminderMode.trueFalse,
    );

    test('each reminder shows one statement with the answer buttons', () async {
      await service.sync(uid: 'u1', set: set, settings: trueFalse);

      final scheduled = notifications.scheduled;
      expect(scheduled, hasLength(48));
      final byKey = {for (final q in sampleQuestions()) q.key: q};
      var correctOnes = 0;
      for (final notice in scheduled) {
        expect(notice.title, hu.reminderTrueFalseTitle);
        expect(notice.answerButtons, isTrue);
        final question = byKey[notice.payload.key]!;
        final statement = notice.payload.statement!;
        expect(notice.body, statementText(question, statement));
        if (statement == correctStatement) correctOnes++;
      }
      // About half true, half false.
      expect(correctOnes, inInclusiveRange(14, 34));
    });

    Future<ReminderLaunch> firstStatement() async {
      await service.sync(uid: 'u1', set: set, settings: trueFalse);
      return notifications.scheduled.first.payload;
    }

    test('a right answer: result, next statement, progress and queue', () async {
      final launch = await firstStatement();
      final saidTrue = launch.statement == correctStatement;

      await service.answer(
        ReminderAnswer(launch: launch, saidTrue: saidTrue, notificationId: 77),
      );

      final result = notifications.shown.single;
      expect(result.id, 77);
      expect(result.title, hu.reminderResultCorrect);
      expect(result.quiet, isTrue);
      expect(result.answerButtons, isTrue);
      expect(result.payload.key, isNot(launch.key));
      expect(result.payload.statement, isNotNull);
      expect(store.snapshot!.progress[launch.key]!.box, 1);
      // Synced to Firestore at once while the app runs; queue empty again.
      expect(progress.data['set1']![launch.key]!.correct, 1);
      expect(store.answers, isEmpty);
      // The remaining reminders were planned again.
      expect(notifications.scheduled, hasLength(48));
    });

    test('a wrong answer shows the correct statement', () async {
      final launch = await firstStatement();
      final saidTrue = launch.statement != correctStatement;
      final question =
          sampleQuestions().firstWhere((q) => q.key == launch.key);

      await service.answer(
        ReminderAnswer(launch: launch, saidTrue: saidTrue, notificationId: 5),
      );

      final result = notifications.shown.single;
      expect(result.title, hu.reminderResultWrong);
      expect(
        result.body,
        startsWith(hu.reminderCorrectStatement(question.correct.text)),
      );
      expect(store.snapshot!.progress[launch.key]!.wrong, 1);
    });

    test('in the background the answer waits in the queue', () async {
      final launch = await firstStatement();
      final background = ReminderService(
        store: store,
        notifications: notifications,
        location: tz.getLocation(reminderTimeZone),
        l10n: hu,
        clock: () => now,
        random: Random(3),
      );

      await background.answer(
        ReminderAnswer(launch: launch, saidTrue: true, notificationId: 9),
      );

      expect(store.answers.single.key, launch.key);
      expect(progress.data['set1']?[launch.key], isNull);

      // The next app start writes it to Firestore.
      await service.sync(uid: 'u1', set: set, settings: trueFalse);
      expect(store.answers, isEmpty);
      expect(progress.data['set1']![launch.key]!.seen, 1);
    });

    test('a test notification in this mode has the buttons', () async {
      await service.sync(uid: 'u1', set: set, settings: trueFalse);
      await service.sendTest(uid: 'u1', set: set);
      expect(notifications.shown.single.answerButtons, isTrue);
      expect(notifications.shown.single.payload.statement, isNotNull);
    });
  });

  group('queued answers', () {
    test('are replayed in order; a later lastAt from the app is kept', () {
      final appTime = DateTime.utc(2026, 11, 22, 12);
      final before = ItemProgress(box: 2, seen: 3, correct: 2, wrong: 1, lastAt: appTime);
      final older = QueuedAnswer(
        uid: 'u1',
        setId: 's',
        key: 'k',
        correct: true,
        at: DateTime.utc(2026, 11, 22, 9),
      );
      final after = replayAnswer(before, older);
      expect(after.seen, 4);
      expect(after.correct, 3);
      expect(after.box, 3);
      expect(after.lastAt, appTime);

      final newer = QueuedAnswer(
        uid: 'u1',
        setId: 's',
        key: 'k',
        correct: false,
        at: DateTime.utc(2026, 11, 22, 13),
      );
      final later = replayAnswer(after, newer);
      expect(later.box, 0);
      expect(later.lastAt, newer.at);
    });

    test("another user's answers stay queued", () async {
      store.answers.add(
        QueuedAnswer(uid: 'u2', setId: 'set1', key: 'k', correct: true, at: now),
      );
      await service.sync(uid: 'u1', set: set, settings: on);
      expect(store.answers.single.uid, 'u2');
    });

    test('answers survive the JSON round trip', () {
      final answer = QueuedAnswer(
        uid: 'u1',
        setId: 'set1',
        key: 'k',
        correct: false,
        at: DateTime.fromMillisecondsSinceEpoch(1795300000000),
      );
      final copy = QueuedAnswer.fromMap(answer.toMap())!;
      expect(
        [copy.uid, copy.setId, copy.key, copy.correct, copy.at],
        [answer.uid, answer.setId, answer.key, answer.correct, answer.at],
      );
      expect(QueuedAnswer.fromMap({'uid': 1}), isNull);
    });
  });

  test('buttons are told apart from taps', () {
    const launch = ReminderLaunch(setId: 'set1', key: 'k', statement: 2);
    final payload = launch.encode();
    expect(ReminderLaunch.decode(payload), launch);

    final yes = ReminderResponse.parse(
      actionId: ReminderActions.isTrue,
      payload: payload,
      notificationId: 12,
    )!;
    expect(yes.answer!.saidTrue, isTrue);
    expect(yes.answer!.notificationId, 12);
    expect(yes.launch, isNull);

    final no = ReminderResponse.parse(
      actionId: ReminderActions.isFalse,
      payload: payload,
      notificationId: 12,
    )!;
    expect(no.answer!.saidTrue, isFalse);

    for (final actionId in [null, ReminderActions.all]) {
      final open = ReminderResponse.parse(
        actionId: actionId,
        payload: payload,
        notificationId: 12,
      )!;
      expect(open.launch, launch);
      expect(open.answer, isNull);
    }
    expect(
      ReminderResponse.parse(actionId: null, payload: 'x', notificationId: 1),
      isNull,
    );
  });
}
