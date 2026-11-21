import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:testacer/src/question_format/question_format.dart';
import 'package:testacer/src/questions/question_codec.dart';

void main() {
  test('a question survives the round trip, marks and notes included', () {
    final parsed = parseQuestionSet('''
## 4. Kérdés szövege

1. ✔ **A** ***„Tandoku-Rensu”*** jelentése
2. A „Shihai” jelentése *(megjegyzés)*
''').questionSet.questions.single;

    final copy = questionFromMap(questionToMap(parsed));

    expect(copy.key, parsed.key);
    expect(copy.order, 4);
    expect(copy.prompt, 'Kérdés szövege');
    expect(copy.correct.text, parsed.correct.text);
    expect(copy.correct.marks, parsed.correct.marks);
    expect(copy.wrong.single.note, 'megjegyzés');
  });

  final file = File('data/gyakorlo_teszt_osszes_valasz.md');
  test(
    'every question of the real file survives the round trip',
    () {
      final questions =
          parseQuestionSet(file.readAsStringSync()).questionSet.questions;
      for (final question in questions) {
        final copy = questionFromMap(questionToMap(question));
        expect(copy.key, question.key);
        expect(
          [for (final o in copy.options) o.text],
          [for (final o in question.options) o.text],
        );
        expect(copy.correct.marks, question.correct.marks);
      }
    },
    skip: file.existsSync() ? false : 'data/ question file not present',
  );
}
