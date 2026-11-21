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

  test('the body names the subject, not the answer', () async {
    final yoshi = sampleQuestions().first;
    expect(reminderBody(hu, yoshi), hu.reminderBodySubject('„Yoshi”'));
    expect(reminderBody(hu, null), hu.reminderBodyPlain);
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
}
