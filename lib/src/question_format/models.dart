import 'key.dart';

/// Kind of an emphasised range in an option's text.
enum MarkKind {
  /// `***text***` – the subject of the statement.
  subject,

  /// `**text**` – words that differ from at least one wrong option.
  differs,
}

/// An emphasised range of a [QuestionOption.text].
///
/// [start] and [end] are UTF-16 code-unit offsets, as used by Dart strings
/// and Flutter's `TextSpan`; [end] is exclusive.
class EmphasisMark {
  const EmphasisMark(this.start, this.end, this.kind);

  final int start;
  final int end;
  final MarkKind kind;

  @override
  bool operator ==(Object other) =>
      other is EmphasisMark &&
      other.start == start &&
      other.end == end &&
      other.kind == kind;

  @override
  int get hashCode => Object.hash(start, end, kind);

  @override
  String toString() => 'EmphasisMark($start, $end, ${kind.name})';
}

/// One answer option of a question.
class QuestionOption {
  const QuestionOption({
    required this.text,
    this.marks = const <EmphasisMark>[],
    this.note,
  });

  /// The option's text without emphasis markers.
  final String text;

  /// Emphasised ranges of [text].
  final List<EmphasisMark> marks;

  /// Optional note, shown only in feedback (from a trailing `*(…)*`).
  final String? note;

  /// The text of every mark of [kind], in order of appearance.
  List<String> markedTexts(MarkKind kind) => [
        for (final mark in marks)
          if (mark.kind == kind) text.substring(mark.start, mark.end),
      ];
}

/// A multiple-choice question with exactly one correct option.
class Question {
  Question({
    required this.order,
    required this.correct,
    required this.wrong,
    required this.line,
    this.prompt,
  }) : key = questionKey(correct.text);

  /// Display order: the number in the `## 12.` heading.
  final int order;

  /// Optional prompt: text after the number in the heading.
  final String? prompt;

  /// The correct option.
  final QuestionOption correct;

  /// The wrong options, in file order.
  final List<QuestionOption> wrong;

  /// Stable identifier derived from the correct option's text.
  final String key;

  /// 1-based line number of the question's heading in the source file.
  final int line;

  /// All options, the correct one first.
  List<QuestionOption> get options => [correct, ...wrong];
}

/// A parsed question file.
class QuestionSet {
  const QuestionSet({
    required this.questions,
    this.title,
    this.description = '',
  });

  /// Text of the first level-1 heading, if any.
  final String? title;

  /// Text lines before the first question (other than the title).
  final String description;

  /// The questions in file order.
  final List<Question> questions;
}

/// Severity of a [ParseIssue]. Errors block the import; warnings do not.
enum IssueLevel { error, warning }

/// A problem found while parsing a question file.
class ParseIssue {
  const ParseIssue(this.level, this.line, this.message, {this.order});

  final IssueLevel level;

  /// 1-based line number in the source file.
  final int line;

  /// The question's number, if the issue belongs to a question.
  final int? order;

  final String message;

  @override
  String toString() {
    final where = order == null ? 'line $line' : 'line $line, question $order';
    return '${level.name} ($where): $message';
  }
}

/// The parsed question set plus everything the validator found.
class ParseResult {
  const ParseResult(this.questionSet, this.issues);

  final QuestionSet questionSet;
  final List<ParseIssue> issues;

  List<ParseIssue> get errors =>
      issues.where((issue) => issue.level == IssueLevel.error).toList();

  List<ParseIssue> get warnings =>
      issues.where((issue) => issue.level == IssueLevel.warning).toList();

  bool get hasErrors => issues.any((issue) => issue.level == IssueLevel.error);
}
