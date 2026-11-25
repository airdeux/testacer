import 'package:flutter/services.dart' show appBuildName, appBuildNumber;

/// The app's version as `pubspec.yaml` has it, e.g. `v1.0.5+6`; `null` if
/// unknown.
///
/// Embedded when the app is built, so it is the version of the code that is
/// running – on the web too, even when the browser still runs a cached
/// copy (unlike `version.json`, which is read from the server).
String? appVersionLabel({
  String? name = appBuildName,
  String? number = appBuildNumber,
}) {
  if (name == null || name.isEmpty) return null;
  return number == null || number.isEmpty ? 'v$name' : 'v$name+$number';
}
