import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:testacer/src/import/file_picker_service.dart';
import 'package:testacer/src/ui/import_screen.dart';

import '../support/fakes.dart';

const _goodFile = '''
# Minta kérdéssor

## 1.

1. ✔ A ***„Yoshi”*** jelentése, **fojtasd.**
2. A „Yoshi” jelentése, állj.
3. A „Yoshi” jelentése, rajta.
4. A „Yoshi” jelentése, ne mozdulj.
''';

void main() {
  late TestServices t;

  setUp(() => t = TestServices());

  /// Opens the import screen from a launcher page, so it can pop back.
  Future<void> openImport(WidgetTester tester) async {
    await tester.pumpWidget(
      localized(
        Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(builder: (_) => ImportScreen(services: t.services)),
              ),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );
    await tapVisible(tester, find.text('open'));
  }

  testWidgets('checks a good file and imports it as a new set', (tester) async {
    t.filePicker.next = const PickedTextFile('minta.md', _goodFile);
    await openImport(tester);

    await tapVisible(tester, find.text(hu.pickFile));

    expect(find.text(hu.questionCount(1)), findsOneWidget);
    expect(find.text(hu.importNoIssues), findsOneWidget);
    expect(find.text('Minta kérdéssor'), findsOneWidget); // title field

    await tapVisible(tester, find.text(hu.importButton));

    expect(t.questionSets.imports, ['set1:Minta kérdéssor:minta.md:1:0']);
    expect(find.text('open'), findsOneWidget); // back on the launcher
    expect(find.text(hu.importDone(1)), findsOneWidget);
  });

  testWidgets('blocks a file with errors', (tester) async {
    t.filePicker.next = const PickedTextFile('rossz.md', '## 1.\n\n1. A\n2. B\n');
    await openImport(tester);

    await tapVisible(tester, find.text(hu.pickFile));

    expect(find.text(hu.importHasErrors), findsOneWidget);
    final button = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, hu.importButton),
    );
    expect(button.onPressed, isNull);
  });

  testWidgets('explains a file that is not text', (tester) async {
    t.filePicker.notText = true;
    await openImport(tester);

    await tapVisible(tester, find.text(hu.pickFile));

    expect(find.text(hu.importReadError), findsOneWidget);
  });
}
