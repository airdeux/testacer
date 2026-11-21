import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:testacer/src/quiz/progress.dart';
import 'package:testacer/src/quiz/selection.dart';
import 'package:testacer/src/reminders/planner.dart';
import 'package:testacer/src/reminders/reminder_settings.dart';
import 'package:timezone/data/latest_10y.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

void main() {
  late tz.Location budapest;

  setUpAll(() {
    tz_data.initializeTimeZones();
    budapest = tz.getLocation(reminderTimeZone);
  });

  tz.TZDateTime at(int y, int m, int d, [int h = 0, int min = 0]) =>
      tz.TZDateTime(budapest, y, m, d, h, min);

  String hhmm(tz.TZDateTime t) =>
      '${t.month}-${t.day} ${formatMinutes(t.hour * 60 + t.minute)}';

  group('reminderSlots', () {
    test('hourly 09:00–22:00 from Saturday 15:49: the example in the docs', () {
      final slots = reminderSlots(
        const [ReminderWindow.standard],
        at(2026, 11, 21, 15, 49),
      );

      expect(slots, hasLength(48));
      expect(hhmm(slots.first), '11-21 16:00');
      expect(slots.where((t) => t.day == 21), hasLength(7)); // 16:00…22:00
      expect(slots.where((t) => t.day == 22), hasLength(14));
      expect(slots.where((t) => t.day == 23), hasLength(14));
      expect(hhmm(slots.last), '11-24 21:00');
      for (var i = 1; i < slots.length; i++) {
        expect(slots[i].isAfter(slots[i - 1]), isTrue);
      }
    });

    test('a slot exactly at "now" is not repeated', () {
      final slots = reminderSlots(
        const [ReminderWindow.standard],
        at(2026, 11, 21, 16),
        count: 1,
      );
      expect(hhmm(slots.single), '11-21 17:00');
    });

    test('only the chosen days', () {
      const weekdays = ReminderWindow(
        days: {1, 2, 3, 4, 5},
        start: 8 * 60,
        end: 8 * 60,
        everyMinutes: 60,
      );
      // Saturday 2026-11-21 → next weekday is Monday the 23rd.
      final slots = reminderSlots(const [weekdays], at(2026, 11, 21, 12), count: 6);
      expect(slots.map(hhmm), [
        '11-23 08:00',
        '11-24 08:00',
        '11-25 08:00',
        '11-26 08:00',
        '11-27 08:00',
        '11-30 08:00',
      ]);
    });

    test('overlapping windows give each time once, in order', () {
      const morning = ReminderWindow(
        days: ReminderWindow.everyDay,
        start: 9 * 60,
        end: 11 * 60,
        everyMinutes: 60,
      );
      const often = ReminderWindow(
        days: ReminderWindow.everyDay,
        start: 10 * 60,
        end: 11 * 60,
        everyMinutes: 30,
      );
      final slots =
          reminderSlots(const [morning, often], at(2026, 11, 21, 8), count: 4);
      expect(slots.map(hhmm), [
        '11-21 09:00',
        '11-21 10:00',
        '11-21 10:30',
        '11-21 11:00',
      ]);
    });

    test('a 09:00 reminder stays at 09:00 across the spring change', () {
      const nine = ReminderWindow(
        days: ReminderWindow.everyDay,
        start: 9 * 60,
        end: 9 * 60,
        everyMinutes: 60,
      );
      // Summer time starts on Sunday 2026-03-29 at 02:00.
      final slots = reminderSlots(const [nine], at(2026, 3, 28, 10), count: 2);
      expect(slots.map(hhmm), ['3-29 09:00', '3-30 09:00']);
      expect(slots.first.toUtc().hour, 7); // CEST, UTC+2
      expect(
        reminderSlots(const [nine], at(2026, 3, 27, 10), count: 1)
            .single
            .toUtc()
            .hour,
        8, // still CET, UTC+1
      );
    });

    test('a 09:00 reminder stays at 09:00 across the autumn change', () {
      const nine = ReminderWindow(
        days: ReminderWindow.everyDay,
        start: 9 * 60,
        end: 9 * 60,
        everyMinutes: 60,
      );
      // Summer time ends on Sunday 2026-10-25 at 03:00.
      final slots = reminderSlots(const [nine], at(2026, 10, 24, 10), count: 2);
      expect(slots.map(hhmm), ['10-25 09:00', '10-26 09:00']);
      expect(slots.map((t) => t.toUtc().hour), [8, 8]); // CET, UTC+1
      expect(
        slots.last.difference(slots.first),
        const Duration(hours: 24),
      );
    });

    test('a window through the night of the change has no duplicates', () {
      const night = ReminderWindow(
        days: ReminderWindow.everyDay,
        start: 0,
        end: 4 * 60,
        everyMinutes: 30,
      );
      final slots = reminderSlots(const [night], at(2026, 3, 28, 23), count: 9);
      final instants = slots.map((t) => t.millisecondsSinceEpoch).toSet();
      expect(instants, hasLength(slots.length));
    });

    test('no valid window, no slots', () {
      const noDays = ReminderWindow(
        days: {},
        start: 9 * 60,
        end: 22 * 60,
        everyMinutes: 60,
      );
      expect(reminderSlots(const [], at(2026, 11, 21)), isEmpty);
      expect(reminderSlots(const [noDays], at(2026, 11, 21)), isEmpty);
    });
  });

  group('assignQuestions', () {
    final keys = [for (var i = 0; i < 60; i++) 'q$i'];
    final slots = reminderSlots(
      const [ReminderWindow.standard],
      tz.TZDateTime(tz.UTC, 2026, 11, 21, 12),
    );

    test('no repeats while enough questions are left', () {
      final plan = assignQuestions(
        slots,
        keys,
        const {},
        picker: QuestionPicker(random: Random(1)),
      );
      expect(plan, hasLength(48));
      expect(plan.map((p) => p.key).toSet(), hasLength(48));
      expect(plan.map((p) => p.time), slots);
    });

    test('skippable questions are never planned', () {
      final progress = {
        for (var i = 0; i < 55; i++) 'q$i': const ItemProgress(skippable: true),
      };
      final plan = assignQuestions(
        slots,
        keys,
        progress,
        picker: QuestionPicker(random: Random(2)),
      );
      expect(plan, hasLength(48));
      expect(plan.map((p) => p.key).toSet(), {'q55', 'q56', 'q57', 'q58', 'q59'});
      // With 5 questions, the same one never comes twice in a row.
      for (var i = 1; i < plan.length; i++) {
        expect(plan[i].key, isNot(plan[i - 1].key));
      }
    });

    test('everything skippable: nothing to plan', () {
      final plan = assignQuestions(slots, const ['a'], const {
        'a': ItemProgress(skippable: true),
      });
      expect(plan, isEmpty);
    });

    test('notification ids are unique per time', () {
      final plan = assignQuestions(slots, keys, const {});
      expect(plan.map((p) => p.id).toSet(), hasLength(plan.length));
    });
  });
}
