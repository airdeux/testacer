import 'package:flutter_test/flutter_test.dart';
import 'package:testacer/src/reminders/reminder_settings.dart';

void main() {
  test('times are stored as HH:MM', () {
    expect(formatMinutes(9 * 60 + 5), '09:05');
    expect(parseMinutes('09:05'), 545);
    expect(parseMinutes('9:05'), 545);
    expect(parseMinutes('24:00'), isNull);
    expect(parseMinutes('9.05'), isNull);
  });

  test('settings survive a round trip through the stored map', () {
    const settings = ReminderSettings(
      enabled: true,
      windows: [
        ReminderWindow.standard,
        ReminderWindow(days: {6, 7}, start: 10 * 60, end: 12 * 60, everyMinutes: 30),
      ],
    );
    final map = settings.toMap();
    expect(map['windows'], [
      {'days': [1, 2, 3, 4, 5, 6, 7], 'start': '09:00', 'end': '22:00', 'everyMinutes': 60},
      {'days': [6, 7], 'start': '10:00', 'end': '12:00', 'everyMinutes': 30},
    ]);
    expect(ReminderSettings.fromMap(map), settings);
  });

  test('missing data gives the defaults; malformed windows are dropped', () {
    expect(ReminderSettings.fromMap(null), const ReminderSettings());
    final settings = ReminderSettings.fromMap({
      'enabled': true,
      'mode': 'nonsense',
      'windows': [
        {'days': [1], 'start': '22:00', 'end': '09:00', 'everyMinutes': 60},
        {'days': [1], 'start': 'x', 'end': '09:00', 'everyMinutes': 60},
        {'days': [2], 'start': '08:00', 'end': '09:00', 'everyMinutes': 30},
      ],
    });
    expect(settings.enabled, isTrue);
    expect(settings.mode, ReminderMode.open);
    expect(settings.windows, [
      const ReminderWindow(days: {2}, start: 8 * 60, end: 9 * 60, everyMinutes: 30),
    ]);
  });

  test('reminders per day', () {
    expect(ReminderWindow.standard.perDay, 14);
    expect(
      const ReminderWindow(days: {1}, start: 9 * 60, end: 10 * 60, everyMinutes: 45)
          .perDay,
      2,
    );
    expect(
      const ReminderWindow(days: {1}, start: 9 * 60, end: 9 * 60, everyMinutes: 10)
          .isValid,
      isFalse, // shorter than 15 minutes
    );
  });
}
