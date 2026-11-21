import 'package:material_ui/material_ui.dart';

import '../question_format/models.dart';

/// An option's text with its emphasis: the subject in bold italic, the
/// distinguishing words in bold (decision D-007: shown only in feedback).
class EmphasizedText extends StatelessWidget {
  const EmphasizedText(this.option, {super.key, this.style});

  final QuestionOption option;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    final text = option.text;
    final marks = option.marks.toList()..sort((a, b) => a.start.compareTo(b.start));
    final spans = <InlineSpan>[];
    var position = 0;
    for (final mark in marks) {
      if (mark.start < position) continue;
      if (mark.start > position) {
        spans.add(TextSpan(text: text.substring(position, mark.start)));
      }
      spans.add(
        TextSpan(
          text: text.substring(mark.start, mark.end),
          style: mark.kind == MarkKind.subject
              ? const TextStyle(fontWeight: FontWeight.w700, fontStyle: FontStyle.italic)
              : const TextStyle(fontWeight: FontWeight.w700),
        ),
      );
      position = mark.end;
    }
    if (position < text.length) spans.add(TextSpan(text: text.substring(position)));
    return Text.rich(TextSpan(style: style, children: spans));
  }
}
