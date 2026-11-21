import 'dart:convert';

import 'key.dart';
import 'models.dart';

final _title = RegExp(r'^#\s+(.+)$');
final _heading = RegExp(r'^##\s+(\d+)\.?\s*(.*)$');
final _option = RegExp(r'^\d+\.\s+(.*)$');
final _check = RegExp('^✔️?\\s*');
final _note = RegExp(r'\s*\*\(([^*]*)\)\*$');

/// Parses a question file in the format described in docs/question-format.md.
ParseResult parseQuestionSet(String markdown) => _Parser().parse(markdown);

/// Result of reading the emphasis markers out of one option.
class EmphasisParse {
  const EmphasisParse(this.text, this.marks, this.note, this.problems);

  /// Plain text without markers (and without the note).
  final String text;

  final List<EmphasisMark> marks;

  /// Text of a trailing `*(…)*` note, without the parentheses.
  final String? note;

  /// Human-readable problems, reported as warnings by the parser.
  final List<String> problems;
}

/// Splits [raw] into plain text, emphasis marks and an optional trailing note.
///
/// `***x***` marks a subject, `**x**` marks differing words. Plain `*x*`
/// outside a trailing note is kept as text and reported as a problem.
EmphasisParse parseEmphasis(String raw) {
  String? note;
  var body = raw.trim();
  final noteMatch = _note.firstMatch(body);
  if (noteMatch != null) {
    note = noteMatch.group(1)!.trim();
    body = body.substring(0, noteMatch.start).trimRight();
  }

  final text = StringBuffer();
  final marks = <EmphasisMark>[];
  final problems = <String>[];
  var bold = false;
  var italic = false;
  var spanStart = 0;
  var i = 0;
  while (i < body.length) {
    if (body[i] != '*') {
      text.write(body[i]);
      i++;
      continue;
    }
    var run = 0;
    while (i < body.length && body[i] == '*') {
      run++;
      i++;
    }
    if (run > 3) problems.add('more than 3 "*" characters in a row');
    _closeSpan(bold, italic, spanStart, text.length, marks, problems);
    if (run >= 3) {
      bold = !bold;
      italic = !italic;
    } else if (run == 2) {
      bold = !bold;
    } else {
      italic = !italic;
    }
    spanStart = text.length;
  }
  if (bold || italic) {
    problems.add('unbalanced emphasis markers');
    _closeSpan(bold, italic, spanStart, text.length, marks, problems);
  }
  return EmphasisParse(
    text.toString(),
    List.unmodifiable(marks),
    note,
    List.unmodifiable(problems),
  );
}

void _closeSpan(
  bool bold,
  bool italic,
  int start,
  int end,
  List<EmphasisMark> marks,
  List<String> problems,
) {
  if (end <= start || (!bold && !italic)) return;
  if (bold && italic) {
    marks.add(EmphasisMark(start, end, MarkKind.subject));
  } else if (bold) {
    marks.add(EmphasisMark(start, end, MarkKind.differs));
  } else {
    problems.add('italic text outside a note is shown as plain text');
  }
}

class _DraftOption {
  _DraftOption(this.isCorrect, this.parsed, this.line);

  final bool isCorrect;
  final EmphasisParse parsed;
  final int line;

  QuestionOption toOption() =>
      QuestionOption(text: parsed.text, marks: parsed.marks, note: parsed.note);
}

class _DraftQuestion {
  _DraftQuestion(this.order, this.prompt, this.line);

  final int order;
  final String prompt;
  final int line;
  final options = <_DraftOption>[];
}

class _Parser {
  final _issues = <ParseIssue>[];
  final _questions = <Question>[];
  final _description = <String>[];
  String? _setTitle;
  _DraftQuestion? _draft;

  ParseResult parse(String markdown) {
    final lines = const LineSplitter().convert(markdown);
    for (var i = 0; i < lines.length; i++) {
      _readLine(lines[i].trimRight(), i + 1);
    }
    _finishQuestion();
    _checkSet();
    return ParseResult(
      QuestionSet(
        title: _setTitle,
        description: _description.join('\n'),
        questions: List.unmodifiable(_questions),
      ),
      List.unmodifiable(_issues),
    );
  }

  void _readLine(String line, int lineNo) {
    if (line.trim().isEmpty) return;

    final heading = _heading.firstMatch(line);
    if (heading != null) {
      _finishQuestion();
      _draft = _DraftQuestion(
        int.parse(heading.group(1)!),
        heading.group(2)!.trim(),
        lineNo,
      );
      return;
    }

    final draft = _draft;
    if (draft == null) {
      final title = _title.firstMatch(line);
      if (title != null && _setTitle == null) {
        _setTitle = title.group(1)!.trim();
      } else {
        _description.add(line.trim());
      }
      return;
    }

    final option = _option.firstMatch(line);
    if (option == null) {
      _issue(
        IssueLevel.error,
        lineNo,
        'unrecognised line: "${_shorten(line)}"',
        draft.order,
      );
      return;
    }
    var rest = option.group(1)!;
    final check = _check.firstMatch(rest);
    if (check != null) rest = rest.substring(check.end);
    final parsed = parseEmphasis(rest);
    for (final problem in parsed.problems) {
      _issue(IssueLevel.warning, lineNo, problem, draft.order);
    }
    draft.options.add(_DraftOption(check != null, parsed, lineNo));
  }

  void _finishQuestion() {
    final draft = _draft;
    if (draft == null) return;
    _draft = null;

    final order = draft.order;
    final options = draft.options;
    if (options.length < 2) {
      _issue(
        IssueLevel.error,
        draft.line,
        'needs at least 2 options, found ${options.length}',
        order,
      );
      return;
    }
    final correct = options.where((option) => option.isCorrect).toList();
    if (correct.length != 1) {
      _issue(
        IssueLevel.error,
        draft.line,
        correct.isEmpty
            ? 'no option is marked with ✔'
            : '${correct.length} options are marked with ✔',
        order,
      );
      return;
    }
    final seen = <String>{};
    for (final option in options) {
      if (!seen.add(normalizeForKey(option.parsed.text))) {
        _issue(
          IssueLevel.error,
          option.line,
          'the same option appears twice',
          order,
        );
        return;
      }
    }
    if (options.length != 4) {
      _issue(
        IssueLevel.warning,
        draft.line,
        '${options.length} options instead of 4',
        order,
      );
    }
    _questions.add(
      Question(
        order: order,
        prompt: draft.prompt.isEmpty ? null : draft.prompt,
        correct: correct.single.toOption(),
        wrong: [
          for (final option in options)
            if (!option.isCorrect) option.toOption(),
        ],
        line: draft.line,
      ),
    );
  }

  void _checkSet() {
    if (_questions.isEmpty && !_issues.any((i) => i.level == IssueLevel.error)) {
      _issue(IssueLevel.error, 1, 'no questions found');
    }
    final byKey = <String, Question>{};
    final orders = <int>{};
    for (final question in _questions) {
      final first = byKey[question.key];
      if (first != null) {
        _issue(
          IssueLevel.error,
          question.line,
          'same correct answer as question ${first.order}',
          question.order,
        );
      } else {
        byKey[question.key] = question;
      }
      if (!orders.add(question.order)) {
        _issue(
          IssueLevel.warning,
          question.line,
          'question number ${question.order} is used more than once',
          question.order,
        );
      }
    }
  }

  void _issue(IssueLevel level, int line, String message, [int? order]) =>
      _issues.add(ParseIssue(level, line, message, order: order));
}

String _shorten(String text) =>
    text.length <= 60 ? text : '${text.substring(0, 57)}…';
