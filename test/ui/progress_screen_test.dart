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

  group('Haladás törlése', () {
    late TestServices t;
    late List questions;

    Future<void> open(WidgetTester tester, {bool withSkippable = true}) async {
      t = TestServices();
      final qs = sampleQuestions();
      questions = qs;
      final set = t.questionSets.add('set1', 'Gyakorló teszt', qs);
      t.progress.data['set1'] = {
        qs[0].key: const ItemProgress(box: 2, seen: 3, correct: 2, wrong: 1),
        if (withSkippable)
          qs[1].key: const ItemProgress(box: 4, seen: 4, correct: 4, skippable: true),
      };
      await tester.pumpWidget(
        localized(ProgressScreen(services: t.services, user: testUser(), questionSet: set)),
      );
      await tester.pumpAndSettle();
      // The button is at the bottom of a lazily built list.
      await tester.scrollUntilVisible(
        find.text(hu.resetProgress),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tapVisible(tester, find.text(hu.resetProgress));
    }

    testWidgets('keeps the Bébikönnyű list if asked', (tester) async {
      await open(tester);
      expect(find.text(hu.resetProgressSkippableQuestion(1)), findsOneWidget);

      await tapVisible(tester, find.text(hu.resetKeepSkippable));

      expect(t.progress.resets, ['set1:keep1']);
      expect(t.progress.data['set1']!.keys, [questions[1].key]);
      expect(find.text(hu.progressSeen(0, 3)), findsOneWidget);
      expect(find.text(hu.progressSkippedTitle(1)), findsOneWidget);
      expect(find.text(hu.resetDone), findsOneWidget);
    });

    testWidgets('or deletes it too', (tester) async {
      await open(tester);

      await tapVisible(tester, find.text(hu.resetEverything));

      expect(t.progress.resets, ['set1:keep0']);
      expect(find.text(hu.progressSkippedTitle(0)), findsOneWidget);
    });

    testWidgets('Mégse changes nothing', (tester) async {
      await open(tester);

      await tapVisible(tester, find.text(hu.cancelButton));

      expect(t.progress.resets, isEmpty);
      expect(t.progress.data['set1'], hasLength(2));
      expect(find.text(hu.resetDone), findsNothing);
    });

    testWidgets('without Bébikönnyű questions there is no list to ask about',
        (tester) async {
      await open(tester, withSkippable: false);
      expect(
        find.descendant(
          of: find.byType(AlertDialog),
          matching: find.textContaining('bébikönnyű'),
        ),
        findsNothing,
      );
      expect(find.text(hu.resetKeepSkippable), findsNothing);

      await tapVisible(tester, find.text(hu.resetConfirm));
      expect(t.progress.resets, ['set1:keep0']);
    });
  });
}
