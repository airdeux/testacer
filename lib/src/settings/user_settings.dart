import '../quiz/quiz_length.dart';

/// Per-user settings, synced between devices (`users/{uid}`).
class UserSettings {
  const UserSettings({this.activeSetId, this.quizLength = QuizLength.ten});

  /// The question set the user practises; `null` until chosen.
  final String? activeSetId;
  final QuizLength quizLength;
}

abstract interface class UserSettingsRepository {
  /// Current settings, then every change (defaults if none are stored).
  Stream<UserSettings> watch(String uid);

  Future<void> update(String uid, {String? activeSetId, QuizLength? quizLength});
}
