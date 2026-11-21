import 'package:material_ui/material_ui.dart';

import '../l10n/app_localizations.dart';
import 'access/access_repository.dart';
import 'auth/auth_service.dart';
import 'auth/email_link_controller.dart';
import 'localization.dart';
import 'ui/auth_gate.dart';

/// The app shell: theme, Hungarian localisation, and the sign-in gate.
class TestAcerApp extends StatelessWidget {
  const TestAcerApp({
    super.key,
    required this.auth,
    required this.access,
    required this.emailLinks,
  });

  final AuthService auth;
  final AccessRepository access;
  final EmailLinkController emailLinks;

  static const _seed = Color(0xFF1F3A93);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      onGenerateTitle: (context) => AppLocalizations.of(context).appTitle,
      debugShowCheckedModeBanner: false,
      theme: ThemeData(colorScheme: ColorScheme.fromSeed(seedColor: _seed)),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: _seed,
          brightness: Brightness.dark,
        ),
      ),
      locale: const Locale('hu'),
      localizationsDelegates: appLocalizationsDelegates,
      supportedLocales: appSupportedLocales,
      home: AuthGate(auth: auth, access: access, emailLinks: emailLinks),
    );
  }
}
