import 'dart:convert';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;

/// A notification to show now or at [time].
class ReminderNotice {
  const ReminderNotice({
    required this.id,
    this.title,
    this.body,
    required this.payload,
    this.time,
    this.answerButtons = false,
    this.quiet = false,
  });

  final int id;

  /// Only what is needed, so long statements fit (no filler text).
  final String? title;
  final String? body;
  final ReminderLaunch payload;
  final tz.TZDateTime? time;

  /// Igaz / Hamis / Összes válasz (mode `trueFalse`, D-005).
  final bool answerButtons;

  /// Replaces a notification on screen without sound or vibration (the
  /// result of an answer given in the notification).
  final bool quiet;
}

/// What a reminder refers to: question [key] of set [setId] and, in
/// true/false mode, the [statement] shown ([correctStatement] or the index
/// of a wrong option).
class ReminderLaunch {
  const ReminderLaunch({
    required this.setId,
    required this.key,
    this.statement,
  });

  final String setId;
  final String key;
  final int? statement;

  String encode() => jsonEncode({
        'set': setId,
        'q': key,
        'w': ?statement,
      });

  static ReminderLaunch? decode(String? payload) {
    if (payload == null) return null;
    try {
      final data = jsonDecode(payload);
      if (data case {'set': final String setId, 'q': final String key}) {
        final statement = data['w'];
        return ReminderLaunch(
          setId: setId,
          key: key,
          statement: statement is int ? statement : null,
        );
      }
    } on FormatException {
      // Not one of ours.
    }
    return null;
  }

  @override
  bool operator ==(Object other) =>
      other is ReminderLaunch &&
      other.setId == setId &&
      other.key == key &&
      other.statement == statement;

  @override
  int get hashCode => Object.hash(setId, key, statement);
}

/// The statement of a true/false reminder is the correct option.
const correctStatement = -1;

/// Igaz or Hamis pressed on the reminder [notificationId].
class ReminderAnswer {
  const ReminderAnswer({
    required this.launch,
    required this.saidTrue,
    required this.notificationId,
  });

  final ReminderLaunch launch;
  final bool saidTrue;
  final int notificationId;
}

/// Action ids of the reminder buttons.
abstract final class ReminderActions {
  static const isTrue = 'true';
  static const isFalse = 'false';
  static const all = 'all';
}

/// A tap on a reminder or one of its buttons, sorted out: either a quiz to
/// open ([launch]) or an answer to record ([answer]).
class ReminderResponse {
  const ReminderResponse._({this.launch, this.answer});

  final ReminderLaunch? launch;
  final ReminderAnswer? answer;

  /// `null` for notifications that are not reminders.
  static ReminderResponse? parse({
    required String? actionId,
    required String? payload,
    required int? notificationId,
  }) {
    final launch = ReminderLaunch.decode(payload);
    if (launch == null) return null;
    return switch (actionId) {
      ReminderActions.isTrue || ReminderActions.isFalse => ReminderResponse._(
          answer: ReminderAnswer(
            launch: launch,
            saidTrue: actionId == ReminderActions.isTrue,
            notificationId: notificationId ?? 0,
          ),
        ),
      _ => ReminderResponse._(launch: launch),
    };
  }

  static ReminderResponse? fromNotification(NotificationResponse response) =>
      parse(
        actionId: response.actionId,
        payload: response.payload,
        notificationId: response.id,
      );
}

/// The platform's notifications, as the reminder code needs them. Android
/// only; tests use a fake.
abstract interface class ReminderNotifications {
  /// Must be called before the other methods. While the app runs, [onTap]
  /// receives taps on a reminder or its „Összes válasz” button, [onAnswer]
  /// Igaz / Hamis presses (usually these go to the background handler).
  Future<void> initialize({
    void Function(ReminderLaunch launch)? onTap,
    void Function(ReminderAnswer answer)? onAnswer,
  });

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

/// Button texts, from the app's translations.
class ReminderLabels {
  const ReminderLabels({
    required this.channelName,
    required this.channelDescription,
    required this.isTrue,
    required this.isFalse,
    required this.all,
  });

  final String channelName;
  final String channelDescription;
  final String isTrue;
  final String isFalse;
  final String all;
}

/// [ReminderNotifications] with flutter_local_notifications.
class LocalReminderNotifications implements ReminderNotifications {
  LocalReminderNotifications({
    required this.labels,
    this.backgroundHandler,
    FlutterLocalNotificationsPlugin? plugin,
  }) : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  static const _channelId = 'reminders';

  /// Monochrome status-bar icon (android/app/src/main/res/drawable).
  static const _icon = 'ic_stat_reminder';

  final ReminderLabels labels;

  /// Igaz / Hamis presses while the app is not running; a top-level
  /// function marked `@pragma('vm:entry-point')`.
  final DidReceiveBackgroundNotificationResponseCallback? backgroundHandler;
  final FlutterLocalNotificationsPlugin _plugin;

  AndroidFlutterLocalNotificationsPlugin? get _android =>
      _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();

  NotificationDetails _details(ReminderNotice notice) => NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          labels.channelName,
          channelDescription: labels.channelDescription,
          importance: Importance.high,
          priority: Priority.high,
          category: AndroidNotificationCategory.reminder,
          // Long statements: the expanded notification shows all of it.
          styleInformation: notice.body == null
              ? null
              : BigTextStyleInformation(notice.body!),
          onlyAlertOnce: notice.quiet,
          actions: notice.answerButtons
              ? [
                  // Answered in the background; the notification stays and
                  // is replaced by the result.
                  AndroidNotificationAction(
                    ReminderActions.isTrue,
                    labels.isTrue,
                    cancelNotification: false,
                  ),
                  AndroidNotificationAction(
                    ReminderActions.isFalse,
                    labels.isFalse,
                    cancelNotification: false,
                  ),
                  AndroidNotificationAction(
                    ReminderActions.all,
                    labels.all,
                    showsUserInterface: true,
                  ),
                ]
              : null,
        ),
      );

  @override
  Future<void> initialize({
    void Function(ReminderLaunch launch)? onTap,
    void Function(ReminderAnswer answer)? onAnswer,
  }) async {
    await _plugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings(_icon),
      ),
      onDidReceiveNotificationResponse: (response) {
        final parsed = ReminderResponse.fromNotification(response);
        if (parsed?.launch case final launch?) onTap?.call(launch);
        if (parsed?.answer case final answer?) onAnswer?.call(answer);
      },
      onDidReceiveBackgroundNotificationResponse: backgroundHandler,
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
        notificationDetails: _details(notice),
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
        notificationDetails: _details(notice),
        payload: notice.payload.encode(),
      );
}
