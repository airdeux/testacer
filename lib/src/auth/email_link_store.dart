import 'package:shared_preferences/shared_preferences.dart';

/// Remembers which address a sign-in link was sent to, so a link opened on
/// the same device signs in without asking for the address again.
abstract interface class EmailLinkStore {
  Future<String?> read();

  Future<void> write(String email);

  Future<void> clear();
}

class SharedPrefsEmailLinkStore implements EmailLinkStore {
  static const _key = 'emailForSignInLink';
  final _prefs = SharedPreferencesAsync();

  @override
  Future<String?> read() => _prefs.getString(_key);

  @override
  Future<void> write(String email) => _prefs.setString(_key, email);

  @override
  Future<void> clear() => _prefs.remove(_key);
}
