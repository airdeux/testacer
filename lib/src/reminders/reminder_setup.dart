import 'dart:async';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_10y.dart' as tz_data;
import 'package:workmanager/workmanager.dart';

import '../../l10n/app_localizations.dart';
import '../questions/question_set_repository.dart';
import '../quiz/progress_repository.dart';
import 'reminder_notifications.dart';
import 'reminder_service.dart';
import 'reminder_store.dart';

/// Name of the periodic background job that re-plans the reminders.
const reminderReplanTask = 'reminder-replan';

/// Whether this platform has reminders (Android only, D-004).
bool get remindersSupported =>
    !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

ReminderService createReminderService({
  QuestionSetRepository? questionSets,
  ProgressRepository? progress,
}) {
  tz_data.initializeTimeZones();
  final l10n = lookupAppLocalizations(const Locale('hu'));
  return ReminderService(
    store: SharedPrefsReminderStore(),
    notifications: LocalReminderNotifications(
      labels: ReminderLabels(
        channelName: l10n.reminderChannelName,
        channelDescription: l10n.reminderChannelDescription,
        isTrue: l10n.answerTrue,
        isFalse: l10n.answerFalse,
        all: l10n.answerAll,
      ),
      backgroundHandler: reminderActionInBackground,
    ),
    questionSets: questionSets,
    progress: progress,
    location: reminderLocation(),
    l10n: l10n,
  );
}

/// Sets up reminders at app start: hooks up taps and registers the daily
/// re-planning job. Falls back to [NoReminders] if anything fails, so the
/// app still starts.
Future<Reminders> startReminders({
  required QuestionSetRepository questionSets,
  required ProgressRepository progress,
}) async {
  if (!remindersSupported) return NoReminders();
  try {
    final service = createReminderService(
      questionSets: questionSets,
      progress: progress,
    );
    await service.start();
    await Workmanager().initialize(reminderBackgroundDispatcher);
    await Workmanager().registerPeriodicTask(
      reminderReplanTask,
      reminderReplanTask,
      frequency: const Duration(hours: 12),
      existingWorkPolicy: ExistingPeriodicWorkPolicy.update,
    );
    return service;
  } on Object catch (error) {
    debugPrint('Reminders unavailable: $error');
    return NoReminders();
  }
}

/// Entry point of the background job (runs in its own isolate, without
/// Firebase): re-plans from the snapshot kept on the phone.
@pragma('vm:entry-point')
void reminderBackgroundDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    WidgetsFlutterBinding.ensureInitialized();
    DartPluginRegistrant.ensureInitialized();
    try {
      final service = createReminderService();
      await service.notifications.initialize();
      await service.replanFromStore();
      return true;
    } on Object catch (error) {
      debugPrint('Background re-plan failed: $error');
      return false;
    }
  });
}

/// Igaz / Hamis pressed while the app is not running: the plugin starts this
/// in a background isolate (no Firebase there; the answer is queued).
@pragma('vm:entry-point')
void reminderActionInBackground(NotificationResponse response) {
  final answer = ReminderResponse.fromNotification(response)?.answer;
  if (answer == null) return;
  DartPluginRegistrant.ensureInitialized();
  unawaited(_answerInBackground(answer));
}

Future<void> _answerInBackground(ReminderAnswer answer) async {
  try {
    final service = createReminderService();
    await service.notifications.initialize();
    await service.answer(answer);
  } on Object catch (error) {
    debugPrint('Background answer failed: $error');
  }
}
