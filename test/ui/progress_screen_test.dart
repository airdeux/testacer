import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:testacer/src/quiz/progress.dart';
import 'package:testacer/src/ui/progress_screen.dart';

import '../support/fakes.dart';

/// The number shown in the box row labelled [label].
int rowCount(WidgetTester tester, String label) {
  final row = find.ancestor(of: find.text(label), matching: find.byType(Row)).first;
  final texts = tester
      .widgetList<Text>(find.descendant(of: row, matching: find.byType(Text)))
      .map((text) => text.data)
      .toList();
  return int.parse(texts.last!);
}

void main() {
  testWidgets('shows counts, weak questions, and undoes skippable', (tester) async {
    final t = TestServices();
    final questions = sampleQuestions();
    final set = t.questionSets.add('set1', 'Gyakorló teszt', questions);
    t.progress.data['set1'] = {
      questions[0].key: const ItemProgress(box: 0, seen: 3, correct: 1, wrong: 2),
      questions[1].key: const ItemProgress(box: 4, seen: 4, correct: 4, skippable: true),
    };

    await tester.pumpWidget(
      localized(ProgressScreen(services: t.services, user: testUser(), questionSet: set)),
    );
    await tester.pumpAndSettle();

    expect(find.text(hu.progressSeen(2, 3)), findsOneWidget);
    expect(find.text(hu.progressAccuracy(71)), findsOneWidget); // 5 of 7
    expect(find.text(hu.progressWeakItem(2, 3)), findsOneWidget);
    // The rows add up to all 3 questions: 1 unseen, 1 in box 0, 1 skippable.
    expect(rowCount(tester, hu.progressUnseen), 1);
    expect(rowCount(tester, hu.progressBox0), 1);
    expect(rowCount(tester, hu.progressBox4), 0);
    expect(rowCount(tester, hu.progressSkippedRow), 1);
    expect(find.text(hu.progressSkippedTitle(1)), findsOneWidget);

    await tapVisible(tester, find.text(hu.undoSkippable));

    expect(t.progress.saves.single, '${'set1'}:${questions[1].key}:box4:skipfalse');
    expect(find.text(hu.progressNoSkipped), findsOneWidget);
    expect(find.text(hu.progressSkippedTitle(0)), findsOneWidget);
    expect(rowCount(tester, hu.progressSkippedRow), 0);
    expect(rowCount(tester, hu.progressBox4), 1);
  });
}
