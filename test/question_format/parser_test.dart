import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:testacer/src/question_format/question_format.dart';

const _sample = '''
# Minta

Leírás első sor.

## 3.

1. ✔ A ***„Yoshi”*** jelentése, **fojtasd.**
2. A „Yoshi” jelentése, állj.
3. A „Yoshi” jelentése, rajta.
4. A „Yoshi” jelentése, ne mozdulj. *(megjegyzés)*
''';

/// Builds one question block: `## order.` followed by numbered options.
String _question(int order, List<String> options) {
  final lines = [
    for (var i = 0; i < options.length; i++) '${i + 1}. ${options[i]}',
  ];
  return '## $order.\n\n${lines.join('\n')}\n';
}

void main() {
  group('parseQuestionSet', () {
    test('reads title, description, options, marks and note', () {
      final result = parseQuestionSet(_sample);

      expect(result.issues, isEmpty);
      final set = result.questionSet;
      expect(set.title, 'Minta');
      expect(set.description, 'Leírás első sor.');
      expect(set.questions, hasLength(1));

      final question = set.questions.single;
      expect(question.order, 3);
      expect(question.prompt, isNull);
      expect(question.correct.text, 'A „Yoshi” jelentése, fojtasd.');
      expect(question.correct.markedTexts(MarkKind.subject), ['„Yoshi”']);
      expect(question.correct.markedTexts(MarkKind.differs), ['fojtasd.']);
      expect(question.wrong.map((option) => option.text).toList(), [
        'A „Yoshi” jelentése, állj.',
        'A „Yoshi” jelentése, rajta.',
        'A „Yoshi” jelentése, ne mozdulj.',
      ]);
      expect(question.wrong.last.note, 'megjegyzés');
      expect(question.options.first, same(question.correct));
      expect(question.key, matches(RegExp(r'^[0-9a-f]{16}$')));
    });

    test('reads a prompt after the question number', () {
      final result = parseQuestionSet(
        '## 7. Válassza ki a helyes választ\n\n1. ✔ A\n2. B\n3. C\n4. D\n',
      );

      expect(result.issues, isEmpty);
      expect(
        result.questionSet.questions.single.prompt,
        'Válassza ki a helyes választ',
      );
    });

    test('accepts Windows line endings', () {
      final result = parseQuestionSet(_sample.replaceAll('\n', '\r\n'));

      expect(result.issues, isEmpty);
      expect(
        result.questionSet.questions.single.correct.text,
        'A „Yoshi” jelentése, fojtasd.',
      );
    });

    test('error when no option is marked with ✔', () {
      final result = parseQuestionSet(_question(1, ['A', 'B', 'C', 'D']));

      expect(result.hasErrors, isTrue);
      expect(result.errors.single.order, 1);
      expect(result.questionSet.questions, isEmpty);
    });

    test('error when two options are marked with ✔', () {
      final result = parseQuestionSet(_question(1, ['✔ A', '✔ B', 'C', 'D']));

      expect(result.hasErrors, isTrue);
      expect(result.questionSet.questions, isEmpty);
    });

    test('error with fewer than 2 options', () {
      final result = parseQuestionSet(_question(1, ['✔ A']));

      expect(result.hasErrors, isTrue);
    });

    test('warning, but no error, with 3 options', () {
      final result = parseQuestionSet(_question(1, ['✔ A', 'B', 'C']));

      expect(result.hasErrors, isFalse);
      expect(result.warnings, hasLength(1));
      expect(result.questionSet.questions, hasLength(1));
    });

    test('error for an unrecognised line inside a question', () {
      final result = parseQuestionSet('## 1.\n\n1. ✔ A\n2. B\nvalami más\n');

      expect(result.errors.single.line, 5);
    });

    test('error for identical options', () {
      final result = parseQuestionSet(_question(1, ['✔ A', 'A', 'B', 'C']));

      expect(result.hasErrors, isTrue);
    });

    test('error for two questions with the same correct answer', () {
      final result = parseQuestionSet(
        '${_question(1, ['✔ A', 'B'])}${_question(2, ['✔ A', 'C'])}',
      );

      expect(result.errors.single.order, 2);
    });

    test('error when the file has no questions', () {
      final result = parseQuestionSet('# Csak cím\n');

      expect(result.hasErrors, isTrue);
    });
  });

  group('parseEmphasis', () {
    test('separates subject and differing words', () {
      final parsed = parseEmphasis('**A** ***„Tandoku-Rensu”*** jelentése');

      expect(parsed.text, 'A „Tandoku-Rensu” jelentése');
      expect(parsed.marks, const [
        EmphasisMark(0, 1, MarkKind.differs),
        EmphasisMark(2, 17, MarkKind.subject),
      ]);
      expect(parsed.problems, isEmpty);
    });

    test('reports unbalanced markers', () {
      expect(parseEmphasis('**nyitva marad').problems, isNotEmpty);
    });
  });

  group('questionKey', () {
    test('ignores whitespace differences', () {
      expect(questionKey('A  „Yoshi”\tjelentése '), questionKey('A „Yoshi” jelentése'));
    });

    test('does not depend on emphasis', () {
      final emphasized = parseQuestionSet(_question(1, ['✔ A ***x*** **y**', 'B']));
      final plain = parseQuestionSet(_question(1, ['✔ A x y', 'B']));

      expect(
        emphasized.questionSet.questions.single.key,
        plain.questionSet.questions.single.key,
      );
    });
  });

  group('real question file', () {
    final file = File('data/gyakorlo_teszt_osszes_valasz.md');

    test(
      'parses all 149 questions without issues',
      () {
        final result = parseQuestionSet(file.readAsStringSync());

        expect(result.issues, isEmpty);
        final questions = result.questionSet.questions;
        expect(questions, hasLength(149));
        expect(
          questions.map((q) => q.order).toList(),
          List.generate(149, (i) => i + 1),
        );
        expect(questions.every((q) => q.options.length == 4), isTrue);
        expect(questions.map((q) => q.key).toSet(), hasLength(149));
        expect(questions[2].correct.markedTexts(MarkKind.subject), ['„Yoshi”']);
        expect(
          questions[14].wrong.map((o) => o.note).whereType<String>().toList(),
          ['a teszt ezt is elfogadja, de nem helyes'],
        );
      },
      skip: file.existsSync()
          ? false
          : 'data/gyakorlo_teszt_osszes_valasz.md is not present (git-ignored)',
    );
  });
}
