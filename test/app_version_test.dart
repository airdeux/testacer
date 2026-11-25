import 'package:flutter_test/flutter_test.dart';
import 'package:testacer/src/app_version.dart';

void main() {
  test('the version label is the pubspec version with a v', () {
    expect(appVersionLabel(name: '1.0.5', number: '6'), 'v1.0.5+6');
    expect(appVersionLabel(name: '1.0.5', number: null), 'v1.0.5');
    expect(appVersionLabel(name: null, number: '6'), isNull);
  });

  test('the build embeds the version from pubspec.yaml', () {
    // `flutter test` passes the pubspec version like `flutter build` does.
    expect(appVersionLabel(), matches(RegExp(r'^v\d+\.\d+\.\d+(\+\d+)?$')));
  });
}
