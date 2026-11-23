import 'package:flutter_test/flutter_test.dart';
import 'package:testacer/src/question_format/question_format.dart';

const _file = '''
# Minta

## 1.

1. ✔ A magyar Judo első olimpiai érmét Tuncsik József szerezte.
2. A magyar Judo első olimpiai érmét Kovács Antal szerezte.

---

# Trivia

Ez a sor nem tartozik egyik elemhez sem.

## Olimpiák

Olimpiák, mikor-hol?
- **1964: Tokió**
- ***első*** magyar ***bajnok***

[olimpia]

## Bajnokok

Tudtad?

[európa bajnok], [európa-bajnok]
[világbajnok, VB]

## Shido

- A ***„Shido”*** **„Kinsa”**-t ér.
''';

void main() {
  final result = parseQuestionSet(_file);
  final trivia = result.questionSet.trivia;

  test('the questions before the trivia part are read as usual', () {
    expect(result.questionSet.questions, hasLength(1));
    expect(result.issues.where((i) => i.level == IssueLevel.error), isEmpty);
  });

  test('reads trivia items with their body and keywords', () {
    expect(trivia.map((t) => t.title), ['Olimpiák', 'Bajnokok', 'Shido']);
    expect(trivia[0].body, 'Olimpiák, mikor-hol?\n- **1964: Tokió**\n- ***első*** magyar ***bajnok***');
    expect(trivia[0].keywords, ['olimpia']);
    // Several groups, several lines, commas inside a group.
    expect(trivia[1].keywords, ['európa bajnok', 'európa-bajnok', 'világbajnok', 'VB']);
  });

  test('an item without keywords uses its heading, with a warning', () {
    expect(trivia[2].keywords, ['Shido']);
    expect(
      result.issues.where((i) => i.message.contains('no [keywords]')),
      hasLength(1),
    );
  });

  test('text outside an item is reported and ignored', () {
    expect(
      result.issues.where((i) => i.message.contains('outside an item')),
      hasLength(1),
    );
  });

  test('matches answers that contain a keyword, ignoring case and spaces', () {
    expect(trivia[0].matches(result.questionSet.questions.single.correct.text), isTrue);
    expect(trivia[1].matches('Kovács Antal  Európa-bajnok lett'), isTrue);
    expect(trivia[1].matches('Ő volt az első VB-érmes'), isTrue);
    expect(trivia[1].matches('A „Kinsa” nem kerül fel'), isFalse);
  });

  test('a file without a trivia part has none', () {
    expect(parseQuestionSet('## 1.\n\n1. ✔ a\n2. b\n').questionSet.trivia, isEmpty);
  });
}
