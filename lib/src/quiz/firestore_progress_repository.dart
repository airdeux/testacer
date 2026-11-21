import 'package:cloud_firestore/cloud_firestore.dart';

import 'progress.dart';
import 'progress_repository.dart';

/// One document per user and set, with a map of question key → record, so a
/// quiz start costs a single read.
class FirestoreProgressRepository implements ProgressRepository {
  FirestoreProgressRepository({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  DocumentReference<Map<String, dynamic>> _doc(String uid, String setId) =>
      _db.collection('users').doc(uid).collection('progress').doc(setId);

  @override
  Future<Map<String, ItemProgress>> load(String uid, String setId) async {
    final snapshot = await _doc(uid, setId).get();
    final items = snapshot.data()?['items'] as Map<String, dynamic>? ?? const {};
    return {
      for (final entry in items.entries)
        if (entry.value case final Map<String, dynamic> map)
          entry.key: ItemProgress.fromMap(map),
    };
  }

  @override
  Future<void> save(String uid, String setId, String key, ItemProgress item) =>
      _doc(uid, setId).set({
        'items': {key: item.toMap()},
      }, SetOptions(merge: true));
}
