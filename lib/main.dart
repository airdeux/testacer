import 'package:app_links/app_links.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:material_ui/material_ui.dart';

import 'firebase_options.dart';
import 'src/access/firestore_access_repository.dart';
import 'src/app.dart';
import 'src/app_services.dart';
import 'src/auth/email_link_controller.dart';
import 'src/auth/email_link_store.dart';
import 'src/auth/firebase_auth_service.dart';
import 'src/auth/url_cleaner.dart';
import 'src/import/file_picker_service.dart';
import 'src/questions/firestore_question_set_repository.dart';
import 'src/quiz/firestore_progress_repository.dart';
import 'src/settings/firestore_user_settings_repository.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  // Sign-in link, verification and password reset e-mails in Hungarian
  // (D-010); the app name in them is the project's public-facing name.
  await FirebaseAuth.instance.setLanguageCode('hu');
  // Offline cache on the web too (Android has it by default): questions and
  // progress stay available, and answers sync when the connection returns.
  FirebaseFirestore.instance.settings = const Settings(persistenceEnabled: true);

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
      services: AppServices(
        auth: auth,
        access: FirestoreAccessRepository(),
        emailLinks: emailLinks,
        questionSets: FirestoreQuestionSetRepository(),
        progress: FirestoreProgressRepository(),
        settings: FirestoreUserSettingsRepository(),
        filePicker: PlatformFilePickerService(),
      ),
    ),
  );
}
