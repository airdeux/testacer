import 'dart:convert';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;

/// A notification to show now or at [time].
class ReminderNotice {
  const ReminderNotice({
    required this.id,
    required this.title,
    required this.body,
    required this.payload,
    this.time,
  });

  final int id;
  final String title;
  final String body;
  final ReminderLaunch payload;
  final tz.TZDateTime? time;
}

/// What a tapped reminder asks for: a quick quiz in [setId] that starts with
/// question [key].
class ReminderLaunch {
  const ReminderLaunch({required this.setId, required this.key});

  final String setId;
  final String key;

  String encode() => jsonEncode({'set': setId, 'q': key});

  static ReminderLaunch? decode(String? payload) {
    if (payload == null) return null;
    try {
      if (jsonDecode(payload)
          case {'set': final String setId, 'q': final String key}) {
        return ReminderLaunch(setId: setId, key: key);
      }
    } on FormatException {
      // Not one of ours.
    }
    return null;
  }

  @override
  bool operator ==(Object other) =>
      other is ReminderLaunch && other.setId == setId && other.key == key;

  @override
  int get hashCode => Object.hash(setId, key);
}

/// The platform's notifications, as the reminder code needs them. Android
/// only; tests use a fake.
abstract interface class ReminderNotifications {
  /// Must be called before the other methods; [onTap] receives taps while
  /// the app runs.
  Future<void> initialize({void Function(ReminderLaunch launch)? onTap});

  /// The reminder whose tap started the app, if any.
  Future<ReminderLaunch?> launchedBy();

  /// Asks for the notification permission (Android 13+); true if granted.
  Future<bool> requestPermission();

  Future<bool> areEnabled();

  /// Replaces every scheduled (not yet shown) reminder with [notices].
  Future<void> schedule(List<ReminderNotice> notices);

  /// Cancels every scheduled reminder; shown ones stay.
  Future<void> cancelScheduled();

  Future<void> showNow(ReminderNotice notice);
}

/// [ReminderNotifications] with flutter_local_notifications.
class LocalReminderNotifications implements ReminderNotifications {
  LocalReminderNotifications({
    required this.channelName,
    required this.channelDescription,
    FlutterLocalNotificationsPlugin? plugin,
  }) : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  static const _channelId = 'reminders';

  /// Monochrome status-bar icon (android/app/src/main/res/drawable).
  static const _icon = 'ic_stat_reminder';

  final String channelName;
  final String channelDescription;
  final FlutterLocalNotificationsPlugin _plugin;

  AndroidFlutterLocalNotificationsPlugin? get _android =>
      _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();

  NotificationDetails _details(String body) => NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          channelName,
          channelDescription: channelDescription,
          importance: Importance.high,
          priority: Priority.high,
          category: AndroidNotificationCategory.reminder,
          styleInformation: BigTextStyleInformation(body),
        ),
      );

  @override
  Future<void> initialize({void Function(ReminderLaunch launch)? onTap}) async {
    await _plugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings(_icon),
      ),
      onDidReceiveNotificationResponse: (response) {
        final launch = ReminderLaunch.decode(response.payload);
        if (launch != null) onTap?.call(launch);
      },
    );
  }

  @override
  Future<ReminderLaunch?> launchedBy() async {
    final details = await _plugin.getNotificationAppLaunchDetails();
    if (details == null || !details.didNotificationLaunchApp) return null;
    return ReminderLaunch.decode(details.notificationResponse?.payload);
  }

  @override
  Future<bool> requestPermission() async =>
      await _android?.requestNotificationsPermission() ?? false;

  @override
  Future<bool> areEnabled() async =>
      await _android?.areNotificationsEnabled() ?? false;

  @override
  Future<void> schedule(List<ReminderNotice> notices) async {
    await cancelScheduled();
    for (final notice in notices) {
      await _plugin.zonedSchedule(
        id: notice.id,
        title: notice.title,
        body: notice.body,
        scheduledDate: notice.time!,
        notificationDetails: _details(notice.body),
        // A few minutes' delay is fine; exact alarms need a special
        // permission on recent Android versions.
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        payload: notice.payload.encode(),
      );
    }
  }

  @override
  Future<void> cancelScheduled() => _plugin.cancelAllPendingNotifications();

  @override
  Future<void> showNow(ReminderNotice notice) => _plugin.show(
        id: notice.id,
        title: notice.title,
        body: notice.body,
        notificationDetails: _details(notice.body),
        payload: notice.payload.encode(),
      );
}
