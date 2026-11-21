import 'package:cloud_firestore/cloud_firestore.dart';

import '../quiz/quiz_length.dart';
import '../reminders/reminder_settings.dart';
import 'user_settings.dart';

class FirestoreUserSettingsRepository implements UserSettingsRepository {
  FirestoreUserSettingsRepository({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  DocumentReference<Map<String, dynamic>> _doc(String uid) =>
      _db.collection('users').doc(uid);

  @override
  Stream<UserSettings> watch(String uid) => _doc(uid).snapshots().map((doc) {
        final data = doc.data() ?? const <String, dynamic>{};
        final settings = data['settings'] as Map<String, dynamic>? ?? const {};
        return UserSettings(
          activeSetId: data['activeSetId'] as String?,
          quizLength: QuizLength.fromName(settings['quizLength']),
          reminders: ReminderSettings.fromMap(settings['notifications']),
        );
      });

  @override
  Future<void> update(
    String uid, {
    String? activeSetId,
    QuizLength? quizLength,
    ReminderSettings? reminders,
  }) =>
      _doc(uid).set({
        'activeSetId': ?activeSetId,
        if (quizLength != null || reminders != null)
          'settings': {
            'quizLength': ?quizLength?.name,
            'notifications': ?reminders?.toMap(),
          },
      }, SetOptions(merge: true));
}
