import 'package:flutter_test/flutter_test.dart';
import 'package:testacer/src/access/access_repository.dart';
import 'package:testacer/src/auth/auth_models.dart';

import '../support/fakes.dart';

void main() {
  group('authErrorKindFromCode', () {
    test('maps the codes the UI explains', () {
      expect(authErrorKindFromCode('invalid-credential'), AuthErrorKind.wrongCredentials);
      expect(authErrorKindFromCode('wrong-password'), AuthErrorKind.wrongCredentials);
      expect(authErrorKindFromCode('email-already-in-use'), AuthErrorKind.emailInUse);
      expect(authErrorKindFromCode('expired-action-code'), AuthErrorKind.invalidLink);
      expect(authErrorKindFromCode('popup-closed-by-user'), AuthErrorKind.cancelled);
      expect(authErrorKindFromCode('network-request-failed'), AuthErrorKind.network);
    });

    test('unknown codes become unknown', () {
      expect(authErrorKindFromCode('something-new'), AuthErrorKind.unknown);
    });
  });

  group('e-mail helpers', () {
    test('normalizeEmail trims and lower-cases', () {
      expect(normalizeEmail('  Foo.Bar@Example.COM '), 'foo.bar@example.com');
    });

    test('isValidEmail accepts addresses and rejects other text', () {
      expect(isValidEmail('a@b.hu'), isTrue);
      expect(isValidEmail(' a@b.hu '), isTrue);
      expect(isValidEmail('a@b'), isFalse);
      expect(isValidEmail('nem e-mail'), isFalse);
    });
  });

  group('AppUser', () {
    test('only unverified password accounts need verification', () {
      expect(testUser(usesPassword: true, emailVerified: false).needsEmailVerification, isTrue);
      expect(testUser(usesPassword: true).needsEmailVerification, isFalse);
      expect(testUser(emailVerified: false).needsEmailVerification, isFalse);
    });

    test('greetingName falls back to the e-mail name', () {
      expect(testUser().greetingName, 'Teszt Elek');
      expect(testUser(displayName: ' ').greetingName, 'tanulo');
    });
  });

  test('roleFromString treats everything but admin as learner', () {
    expect(roleFromString('admin'), AccessRole.admin);
    expect(roleFromString('learner'), AccessRole.learner);
    expect(roleFromString(null), AccessRole.learner);
  });
}
