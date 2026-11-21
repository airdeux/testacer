import 'package:cloud_firestore/cloud_firestore.dart';

import '../auth/auth_models.dart';
import 'access_repository.dart';

/// [AccessRepository] on the `allowlist/{lower-case e-mail}` documents
/// (see firebase/firestore.rules).
class FirestoreAccessRepository implements AccessRepository {
  FirestoreAccessRepository({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> get _allowlist =>
      _db.collection('allowlist');

  @override
  Stream<AccessRole?> watchRole(String email) => _allowlist
      .doc(normalizeEmail(email))
      .snapshots()
      .map((doc) => doc.exists ? roleFromString(doc.data()?['role']) : null);

  @override
  Stream<List<Invitation>> watchInvitations() =>
      _allowlist.snapshots().map((query) {
        final invitations = [
          for (final doc in query.docs)
            Invitation(
              email: doc.id,
              role: roleFromString(doc.data()['role']),
              invitedAt: (doc.data()['invitedAt'] as Timestamp?)?.toDate(),
            ),
        ]..sort((a, b) => a.email.compareTo(b.email));
        return invitations;
      });

  @override
  Future<void> invite(String email, AccessRole role) =>
      _allowlist.doc(normalizeEmail(email)).set({
        'role': role.name,
        'invitedAt': FieldValue.serverTimestamp(),
      });

  @override
  Future<void> revoke(String email) =>
      _allowlist.doc(normalizeEmail(email)).delete();
}
