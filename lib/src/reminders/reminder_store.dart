import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../question_format/models.dart';
import '../questions/question_codec.dart';
import '../quiz/progress.dart';
import 'reminder_settings.dart';

/// What the phone keeps so that reminders can be planned without the
/// network, e.g. by the daily background job: the active set's questions,
/// the user's progress on it and the reminder settings.
class ReminderSnapshot {
  const ReminderSnapshot({
    required this.uid,
    required this.setId,
    required this.setTitle,
    required this.setVersion,
    required this.questions,
    required this.progress,
    required this.settings,
  });

  final String uid;
  final String setId;
  final String setTitle;

  /// The set's import time (ms since the epoch); questions are loaded again
  /// when it changes.
  final int? setVersion;
  final List<Question> questions;
  final Map<String, ItemProgress> progress;
  final ReminderSettings settings;

  Question? question(String key) {
    for (final question in questions) {
      if (question.key == key) return question;
    }
    return null;
  }

  String toJson() => jsonEncode({
        'version': 1,
        'uid': uid,
        'setId': setId,
        'setTitle': setTitle,
        'setVersion': setVersion,
        'questions': [for (final question in questions) questionToMap(question)],
        'progress': {
          for (final entry in progress.entries) entry.key: entry.value.toMap(),
        },
        'settings': settings.toMap(),
      });

  /// `null` when [json] is malformed or from an unknown version.
  static ReminderSnapshot? fromJson(String json) {
    try {
      final data = jsonDecode(json);
      if (data
          case {
            'version': 1,
            'uid': final String uid,
            'setId': final String setId,
            'setTitle': final String setTitle,
            'questions': final List<Object?> questions,
            'progress': final Map<String, Object?> progress,
          }) {
        return ReminderSnapshot(
          uid: uid,
          setId: setId,
          setTitle: setTitle,
          setVersion: (data['setVersion'] as num?)?.toInt(),
          questions: [
            for (final question in questions)
              questionFromMap((question! as Map).cast<String, Object?>()),
          ],
          progress: {
            for (final entry in progress.entries)
              entry.key: ItemProgress.fromMap(
                (entry.value! as Map).cast<String, Object?>(),
              ),
          },
          settings: ReminderSettings.fromMap(data['settings']),
        );
      }
    } on Object {
      // Fall through: a broken snapshot is rebuilt on the next app start.
    }
    return null;
  }
}

abstract interface class ReminderStore {
  Future<ReminderSnapshot?> load();
  Future<void> save(ReminderSnapshot snapshot);
  Future<void> clear();
}

/// [ReminderStore] in shared_preferences (also usable from the background
/// job's isolate).
class SharedPrefsReminderStore implements ReminderStore {
  SharedPrefsReminderStore({SharedPreferencesAsync? preferences})
      : _preferences = preferences ?? SharedPreferencesAsync();

  static const _key = 'reminders.snapshot';

  final SharedPreferencesAsync _preferences;

  @override
  Future<ReminderSnapshot?> load() async {
    final json = await _preferences.getString(_key);
    return json == null ? null : ReminderSnapshot.fromJson(json);
  }

  @override
  Future<void> save(ReminderSnapshot snapshot) =>
      _preferences.setString(_key, snapshot.toJson());

  @override
  Future<void> clear() => _preferences.remove(_key);
}
