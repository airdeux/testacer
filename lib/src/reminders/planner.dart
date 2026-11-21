import 'package:timezone/timezone.dart' as tz;

import '../quiz/progress.dart';
import '../quiz/selection.dart';
import 'reminder_settings.dart';

/// Reminder times are computed in this zone, whatever the phone's zone is.
const reminderTimeZone = 'Europe/Budapest';

/// How many reminders are kept scheduled ahead (architecture § Reminders).
const plannedReminderCount = 48;

/// One scheduled reminder with its pre-picked question.
class PlannedReminder {
  const PlannedReminder(this.time, this.key);

  final tz.TZDateTime time;
  final String key;

  /// Notification id, unique per reminder time (minutes since the epoch).
  int get id => reminderIdFor(time);

  @override
  String toString() => 'PlannedReminder($time, $key)';
}

int reminderIdFor(DateTime time) =>
    (time.millisecondsSinceEpoch ~/ Duration.millisecondsPerMinute) &
    0x7fffffff;

/// The next [count] reminder times strictly after [now], in [now]'s time
/// zone, sorted and without duplicates (overlapping windows).
///
/// Days are counted on the calendar, so a 09:00 reminder stays at 09:00
/// local time across daylight-saving changes. Looks at most [maxDays] ahead.
List<tz.TZDateTime> reminderSlots(
  List<ReminderWindow> windows,
  tz.TZDateTime now, {
  int count = plannedReminderCount,
  int maxDays = 15,
}) {
  final valid = [for (final window in windows) if (window.isValid) window];
  if (valid.isEmpty || count <= 0) return const [];

  final seen = <int>{};
  final slots = <tz.TZDateTime>[];
  for (var offset = 0; offset < maxDays && slots.length < count; offset++) {
    // UTC date arithmetic only to step through calendar days.
    final day = DateTime.utc(now.year, now.month, now.day + offset);
    final daySlots = <tz.TZDateTime>[];
    for (final window in valid) {
      if (!window.days.contains(day.weekday)) continue;
      for (var minute = window.start;
          minute <= window.end;
          minute += window.everyMinutes) {
        final time = tz.TZDateTime(
          now.location,
          day.year,
          day.month,
          day.day,
          minute ~/ 60,
          minute % 60,
        );
        if (time.isAfter(now) && seen.add(time.millisecondsSinceEpoch)) {
          daySlots.add(time);
        }
      }
    }
    slots.addAll(daySlots..sort());
  }
  return slots.take(count).toList();
}

/// Picks a question for each slot with the selection engine (D-006):
/// skippable questions never, no repeats while enough questions are left,
/// never the same one within [QuestionPicker.recentWindow] slots otherwise.
List<PlannedReminder> assignQuestions(
  List<tz.TZDateTime> slots,
  List<String> keys,
  Map<String, ItemProgress> progress, {
  QuestionPicker? picker,
}) {
  final chooser = picker ?? QuestionPicker();
  final picked = <String>[];
  final plan = <PlannedReminder>[];
  for (final time in slots) {
    final key = chooser.pick(
          keys,
          progress,
          recent: picked,
          exclude: picked.toSet(),
        ) ??
        chooser.pick(keys, progress, recent: picked);
    if (key == null) break; // every question is skippable
    picked.add(key);
    plan.add(PlannedReminder(time, key));
  }
  return plan;
}
