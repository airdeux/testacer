/// Reminder settings, synced between devices in
/// `users/{uid}.settings.notifications` (see docs/architecture.md).
library;

/// What a reminder notification offers.
enum ReminderMode {
  /// Tapping opens a short quiz (Phase 5).
  open,

  /// One statement with Igaz / Hamis / Összes válasz buttons (Phase 6).
  trueFalse;

  static ReminderMode fromName(Object? name) => values.firstWhere(
        (mode) => mode.name == name,
        orElse: () => ReminderMode.open,
      );
}

/// A repeating time window, e.g. every day 09:00–22:00, every 60 minutes.
///
/// Times are minutes after midnight in the reminder time zone
/// (Europe/Budapest). [end] is the last possible reminder, so 09:00–22:00
/// every 60 minutes gives 14 reminders a day.
class ReminderWindow {
  const ReminderWindow({
    required this.days,
    required this.start,
    required this.end,
    required this.everyMinutes,
  });

  static const everyDay = {1, 2, 3, 4, 5, 6, 7};
  static const minInterval = 15;

  /// Every day 09:00–22:00, every 60 minutes.
  static const standard = ReminderWindow(
    days: everyDay,
    start: 9 * 60,
    end: 22 * 60,
    everyMinutes: 60,
  );

  /// Weekdays as in [DateTime.weekday]: 1 = Monday … 7 = Sunday.
  final Set<int> days;
  final int start;
  final int end;
  final int everyMinutes;

  bool get isValid =>
      days.isNotEmpty &&
      days.every((day) => day >= 1 && day <= 7) &&
      start >= 0 &&
      end < 24 * 60 &&
      start <= end &&
      everyMinutes >= minInterval;

  /// Reminders per active day.
  int get perDay => isValid ? (end - start) ~/ everyMinutes + 1 : 0;

  ReminderWindow copyWith({
    Set<int>? days,
    int? start,
    int? end,
    int? everyMinutes,
  }) =>
      ReminderWindow(
        days: days ?? this.days,
        start: start ?? this.start,
        end: end ?? this.end,
        everyMinutes: everyMinutes ?? this.everyMinutes,
      );

  Map<String, Object?> toMap() => {
        'days': days.toList()..sort(),
        'start': formatMinutes(start),
        'end': formatMinutes(end),
        'everyMinutes': everyMinutes,
      };

  /// Returns `null` for malformed data.
  static ReminderWindow? fromMap(Object? data) {
    if (data
        case {
          'days': final List<Object?> days,
          'start': final String start,
          'end': final String end,
          'everyMinutes': final num every,
        }) {
      final startMinutes = parseMinutes(start);
      final endMinutes = parseMinutes(end);
      if (startMinutes == null || endMinutes == null) return null;
      final window = ReminderWindow(
        days: {for (final day in days) if (day is num) day.toInt()},
        start: startMinutes,
        end: endMinutes,
        everyMinutes: every.toInt(),
      );
      return window.isValid ? window : null;
    }
    return null;
  }

  @override
  bool operator ==(Object other) =>
      other is ReminderWindow &&
      other.start == start &&
      other.end == end &&
      other.everyMinutes == everyMinutes &&
      other.days.length == days.length &&
      other.days.containsAll(days);

  @override
  int get hashCode =>
      Object.hash(start, end, everyMinutes, Object.hashAllUnordered(days));

  @override
  String toString() =>
      'ReminderWindow(${(days.toList()..sort()).join(',')} '
      '${formatMinutes(start)}–${formatMinutes(end)} /$everyMinutes)';
}

class ReminderSettings {
  const ReminderSettings({
    this.enabled = false,
    this.mode = ReminderMode.open,
    this.windows = const [ReminderWindow.standard],
  });

  final bool enabled;
  final ReminderMode mode;
  final List<ReminderWindow> windows;

  ReminderSettings copyWith({
    bool? enabled,
    ReminderMode? mode,
    List<ReminderWindow>? windows,
  }) =>
      ReminderSettings(
        enabled: enabled ?? this.enabled,
        mode: mode ?? this.mode,
        windows: windows ?? this.windows,
      );

  Map<String, Object?> toMap() => {
        'enabled': enabled,
        'mode': mode.name,
        'windows': [for (final window in windows) window.toMap()],
      };

  /// Defaults for missing data; malformed windows are dropped.
  static ReminderSettings fromMap(Object? data) {
    if (data is! Map) return const ReminderSettings();
    final windows = data['windows'];
    return ReminderSettings(
      enabled: data['enabled'] == true,
      mode: ReminderMode.fromName(data['mode']),
      windows: windows is List
          ? [
              for (final item in windows) ?ReminderWindow.fromMap(item),
            ]
          : const [ReminderWindow.standard],
    );
  }

  @override
  bool operator ==(Object other) =>
      other is ReminderSettings &&
      other.enabled == enabled &&
      other.mode == mode &&
      _sameList(other.windows, windows);

  @override
  int get hashCode => Object.hash(enabled, mode, Object.hashAll(windows));

  static bool _sameList(List<ReminderWindow> a, List<ReminderWindow> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}

/// `9 * 60 + 5` → `"09:05"`.
String formatMinutes(int minutes) =>
    '${(minutes ~/ 60).toString().padLeft(2, '0')}:'
    '${(minutes % 60).toString().padLeft(2, '0')}';

/// `"09:05"` → `545`; `null` if malformed.
int? parseMinutes(String text) {
  final match = RegExp(r'^(\d{1,2}):(\d{2})$').firstMatch(text.trim());
  if (match == null) return null;
  final hours = int.parse(match.group(1)!);
  final minutes = int.parse(match.group(2)!);
  if (hours > 23 || minutes > 59) return null;
  return hours * 60 + minutes;
}
