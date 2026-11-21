/// What an invited user may do.
enum AccessRole { learner, admin }

/// Reads the `role` field of an allowlist entry; anything but `admin` is a
/// learner.
AccessRole roleFromString(Object? value) =>
    value == AccessRole.admin.name ? AccessRole.admin : AccessRole.learner;

/// An entry of the allowlist.
class Invitation {
  const Invitation({required this.email, required this.role, this.invitedAt});

  final String email;
  final AccessRole role;
  final DateTime? invitedAt;
}

/// Invite-only access (decision D-009), backed by the Firestore `allowlist`
/// collection. Implemented with Firestore and with a fake in the tests.
abstract interface class AccessRepository {
  /// The user's role, or `null` while they are not invited. Emits again when
  /// the admin invites or removes them.
  Stream<AccessRole?> watchRole(String email);

  /// All invitations, sorted by e-mail (admins only).
  Stream<List<Invitation>> watchInvitations();

  Future<void> invite(String email, AccessRole role);

  Future<void> revoke(String email);
}
