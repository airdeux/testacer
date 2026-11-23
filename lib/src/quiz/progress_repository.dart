import 'progress.dart';

/// A user's progress per question set (`users/{uid}/progress/{setId}`).
abstract interface class ProgressRepository {
  /// Progress records by question key.
  Future<Map<String, ItemProgress>> load(String uid, String setId);

  /// Stores one question's record. Offline, the write is queued and the
  /// returned future completes only when it reaches the server, so callers
  /// should not wait for it before continuing.
  Future<void> save(String uid, String setId, String key, ItemProgress item);

  /// Deletes the progress on a set. Questions in [keepSkippable] stay marked
  /// skippable (with their counters reset). Offline, completes on reconnect.
  Future<void> reset(
    String uid,
    String setId, {
    Set<String> keepSkippable = const {},
  });
}
