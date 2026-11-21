import 'package:flutter_test/flutter_test.dart';
import 'package:testacer/src/quiz/progress.dart';
import 'package:testacer/src/ui/progress_screen.dart';

import '../support/fakes.dart';

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

    await tapVisible(tester, find.text(hu.undoSkippable));

    expect(t.progress.saves.single, '${'set1'}:${questions[1].key}:box4:skipfalse');
    expect(find.text(hu.progressNoSkipped), findsOneWidget);
  });
}
