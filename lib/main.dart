import 'package:app_links/app_links.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:material_ui/material_ui.dart';

import 'firebase_options.dart';
import 'src/access/firestore_access_repository.dart';
import 'src/app.dart';
import 'src/auth/email_link_controller.dart';
import 'src/auth/email_link_store.dart';
import 'src/auth/firebase_auth_service.dart';
import 'src/auth/url_cleaner.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  final auth = FirebaseAuthService();
  // Started before runApp so the link that opened the app is not missed.
  final emailLinks = EmailLinkController(
    auth: auth,
    store: SharedPrefsEmailLinkStore(),
    links: AppLinks().uriLinkStream,
    onSignInLink: removeQueryFromUrl,
  )..start();

  runApp(
    TestAcerApp(
      auth: auth,
      access: FirestoreAccessRepository(),
      emailLinks: emailLinks,
    ),
  );
}
