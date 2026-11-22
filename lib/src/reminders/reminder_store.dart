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

  ReminderSnapshot copyWith({Map<String, ItemProgress>? progress}) =>
      ReminderSnapshot(
        uid: uid,
        setId: setId,
        setTitle: setTitle,
        setVersion: setVersion,
        questions: questions,
        progress: progress ?? this.progress,
        settings: settings,
      );

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

/// An answer given in a notification, waiting to be synced to Firestore
/// (the background handler has no Firebase).
class QueuedAnswer {
  const QueuedAnswer({
    required this.uid,
    required this.setId,
    required this.key,
    required this.correct,
    required this.at,
  });

  final String uid;
  final String setId;
  final String key;
  final bool correct;
  final DateTime at;

  Map<String, Object?> toMap() => {
        'uid': uid,
        'set': setId,
        'q': key,
        'ok': correct,
        'at': at.millisecondsSinceEpoch,
      };

  static QueuedAnswer? fromMap(Object? data) => switch (data) {
        {
          'uid': final String uid,
          'set': final String setId,
          'q': final String key,
          'ok': final bool correct,
          'at': final int at,
        } =>
          QueuedAnswer(
            uid: uid,
            setId: setId,
            key: key,
            correct: correct,
            at: DateTime.fromMillisecondsSinceEpoch(at),
          ),
        _ => null,
      };
}

abstract interface class ReminderStore {
  Future<ReminderSnapshot?> load();
  Future<void> save(ReminderSnapshot snapshot);

  /// Forgets the snapshot; queued answers stay until they are synced.
  Future<void> clear();

  Future<void> queueAnswer(QueuedAnswer answer);

  /// Removes and returns the queued answers of [uid], oldest first; other
  /// users' answers stay queued.
  Future<List<QueuedAnswer>> takeAnswers(String uid);
}

/// [ReminderStore] in shared_preferences (also usable from the background
/// job's isolate).
class SharedPrefsReminderStore implements ReminderStore {
  SharedPrefsReminderStore({SharedPreferencesAsync? preferences})
      : _preferences = preferences ?? SharedPreferencesAsync();

  static const _key = 'reminders.snapshot';
  static const _answersKey = 'reminders.answers';

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

  Future<List<QueuedAnswer>> _answers() async {
    final json = await _preferences.getString(_answersKey);
    if (json == null) return [];
    try {
      final list = jsonDecode(json);
      if (list is! List) return [];
      return [for (final item in list) ?QueuedAnswer.fromMap(item)];
    } on FormatException {
      return [];
    }
  }

  Future<void> _write(List<QueuedAnswer> answers) => answers.isEmpty
      ? _preferences.remove(_answersKey)
      : _preferences.setString(
          _answersKey,
          jsonEncode([for (final answer in answers) answer.toMap()]),
        );

  @override
  Future<void> queueAnswer(QueuedAnswer answer) async =>
      _write([...await _answers(), answer]);

  @override
  Future<List<QueuedAnswer>> takeAnswers(String uid) async {
    final all = await _answers();
    final mine = [for (final answer in all) if (answer.uid == uid) answer];
    if (mine.isEmpty) return const [];
    await _write([for (final answer in all) if (answer.uid != uid) answer]);
    return mine..sort((a, b) => a.at.compareTo(b.at));
  }
}
