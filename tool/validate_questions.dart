// Validates a question file without importing it.
// Usage: dart run tool/validate_questions.dart <file.md>
import 'dart:io';

import 'package:testacer/src/question_format/question_format.dart';

void main(List<String> args) {
  if (args.length != 1) {
    stderr.writeln('Usage: dart run tool/validate_questions.dart <file.md>');
    exit(64);
  }
  final file = File(args.single);
  if (!file.existsSync()) {
    stderr.writeln('File not found: ${file.path}');
    exit(66);
  }

  final result = parseQuestionSet(file.readAsStringSync());
  final set = result.questionSet;
  final optionCounts = <int, int>{};
  for (final question in set.questions) {
    optionCounts.update(
      question.options.length,
      (count) => count + 1,
      ifAbsent: () => 1,
    );
  }

  stdout.writeln('Title:     ${set.title ?? '(none)'}');
  stdout.writeln('Questions: ${set.questions.length}');
  stdout.writeln(
    'Options:   ${optionCounts.entries.map((e) => '${e.value} × ${e.key}').join(', ')}',
  );
  for (final issue in result.issues) {
    stdout.writeln(issue);
  }
  stdout.writeln(
    result.hasErrors
        ? 'FAILED: ${result.errors.length} error(s)'
        : 'OK (${result.warnings.length} warning(s))',
  );
  exit(result.hasErrors ? 1 : 0);
}
