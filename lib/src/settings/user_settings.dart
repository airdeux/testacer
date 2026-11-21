import '../quiz/quiz_length.dart';
import '../reminders/reminder_settings.dart';

/// Per-user settings, synced between devices (`users/{uid}`).
class UserSettings {
  const UserSettings({
    this.activeSetId,
    this.quizLength = QuizLength.ten,
    this.reminders = const ReminderSettings(),
  });

  /// The question set the user practises; `null` until chosen.
  final String? activeSetId;
  final QuizLength quizLength;

  /// Android reminders (`settings.notifications`); each phone plans its own.
  final ReminderSettings reminders;
}

abstract interface class UserSettingsRepository {
  /// Current settings, then every change (defaults if none are stored).
  Stream<UserSettings> watch(String uid);

  Future<void> update(
    String uid, {
    String? activeSetId,
    QuizLength? quizLength,
    ReminderSettings? reminders,
  });
}
