import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:testacer/l10n/app_localizations.dart';
import 'package:testacer/src/access/access_repository.dart';
import 'package:testacer/src/auth/auth_models.dart';
import 'package:testacer/src/auth/auth_service.dart';
import 'package:testacer/src/auth/email_link_store.dart';
import 'package:testacer/src/localization.dart';

/// Hungarian texts, for finding widgets by their label.
final AppLocalizations hu = lookupAppLocalizations(const Locale('hu'));

/// Wraps [child] in a localised MaterialApp.
Widget localized(Widget child) => MaterialApp(
      locale: const Locale('hu'),
      localizationsDelegates: appLocalizationsDelegates,
      supportedLocales: appSupportedLocales,
      home: child,
    );

/// Scrolls [finder] into view, then taps it.
Future<void> tapVisible(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

AppUser testUser({
  String email = 'tanulo@example.com',
  bool emailVerified = true,
  bool usesPassword = false,
  String? displayName = 'Teszt Elek',
}) =>
    AppUser(
      uid: 'uid-$email',
      email: email,
      displayName: displayName,
      emailVerified: emailVerified,
      usesPassword: usesPassword,
    );

/// Records calls; [nextFailure] makes the next call throw.
class FakeAuthService implements AuthService {
  final _users = StreamController<AppUser?>.broadcast();
  final calls = <String>[];
  AuthFailure? nextFailure;
  bool verifiedOnRefresh = false;

  void emit(AppUser? user) => _users.add(user);

  Future<void> _call(String name) async {
    calls.add(name);
    final failure = nextFailure;
    nextFailure = null;
    if (failure != null) throw failure;
  }

  @override
  Stream<AppUser?> userChanges() => _users.stream;

  @override
  Future<void> signInWithGoogle() => _call('google');

  @override
  Future<void> signInWithPassword(String email, String password) =>
      _call('password:$email');

  @override
  Future<void> registerWithPassword(String email, String password) =>
      _call('register:$email');

  @override
  Future<void> sendPasswordReset(String email) => _call('reset:$email');

  @override
  Future<void> sendSignInLink(String email) => _call('sendLink:$email');

  @override
  bool isSignInLink(String link) => link.contains('mode=signIn');

  @override
  Future<void> signInWithLink(String email, String link) =>
      _call('linkSignIn:$email');

  @override
  Future<void> sendEmailVerification() => _call('verify');

  @override
  Future<bool> refreshEmailVerified() async {
    await _call('refresh');
    return verifiedOnRefresh;
  }

  @override
  Future<void> signOut() => _call('signOut');
}

class FakeEmailLinkStore implements EmailLinkStore {
  String? email;

  @override
  Future<String?> read() async => email;

  @override
  Future<void> write(String email) async => this.email = email;

  @override
  Future<void> clear() async => email = null;
}

class FakeAccessRepository implements AccessRepository {
  final roles = StreamController<AccessRole?>.broadcast();
  final invitations = StreamController<List<Invitation>>.broadcast();
  final calls = <String>[];

  @override
  Stream<AccessRole?> watchRole(String email) => roles.stream;

  @override
  Stream<List<Invitation>> watchInvitations() => invitations.stream;

  @override
  Future<void> invite(String email, AccessRole role) async =>
      calls.add('invite:$email:${role.name}');

  @override
  Future<void> revoke(String email) async => calls.add('revoke:$email');
}
