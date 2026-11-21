import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:testacer/src/auth/auth_models.dart';
import 'package:testacer/src/auth/email_link_controller.dart';

import '../support/fakes.dart';

void main() {
  late FakeAuthService auth;
  late FakeEmailLinkStore store;
  late StreamController<Uri> links;
  late EmailLinkController controller;
  late int cleaned;

  final signInLink = Uri.parse('https://example.com/?mode=signIn&oobCode=x');

  setUp(() {
    auth = FakeAuthService();
    store = FakeEmailLinkStore();
    links = StreamController<Uri>();
    cleaned = 0;
    controller = EmailLinkController(
      auth: auth,
      store: store,
      links: links.stream,
      onSignInLink: () => cleaned++,
    )..start();
  });

  tearDown(() => controller.dispose());

  test('sendLink sends to the normalised address and remembers it', () async {
    await controller.sendLink(' Tanulo@Example.com ');

    expect(auth.calls, ['sendLink:tanulo@example.com']);
    expect(store.email, 'tanulo@example.com');
  });

  test('a link on the same device signs in with the remembered address', () async {
    store.email = 'tanulo@example.com';

    await controller.handleLink(signInLink);

    expect(auth.calls, ['linkSignIn:tanulo@example.com']);
    expect(store.email, isNull);
    expect(controller.status, EmailLinkStatus.idle);
    expect(cleaned, 1);
  });

  test('a link from another device asks for the address', () async {
    await controller.handleLink(signInLink);
    expect(controller.status, EmailLinkStatus.needsEmail);

    await controller.completeWithEmail(' Tanulo@Example.com');

    expect(auth.calls, ['linkSignIn:tanulo@example.com']);
    expect(controller.status, EmailLinkStatus.idle);
  });

  test('other links are ignored', () async {
    await controller.handleLink(Uri.parse('https://example.com/quiz'));

    expect(auth.calls, isEmpty);
    expect(controller.status, EmailLinkStatus.idle);
    expect(cleaned, 0);
  });

  test('a failed sign-in reports the reason', () async {
    store.email = 'tanulo@example.com';
    auth.nextFailure = const AuthFailure(AuthErrorKind.invalidLink);

    await controller.handleLink(signInLink);

    expect(controller.status, EmailLinkStatus.failed);
    expect(controller.error, AuthErrorKind.invalidLink);
  });

  test('links from the stream are handled', () async {
    store.email = 'tanulo@example.com';

    links.add(signInLink);
    await pumpEventQueue();

    expect(auth.calls, ['linkSignIn:tanulo@example.com']);
  });
}
