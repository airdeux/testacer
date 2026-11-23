import 'package:material_ui/material_ui.dart';

import '../../l10n/app_localizations.dart';
import '../question_format/models.dart';
import '../question_format/parser.dart';
import 'emphasized_text.dart';

/// Shows [items] in a bottom sheet over the answer's feedback (D-016).
Future<void> showTrivia(BuildContext context, List<Trivia> items) =>
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => TriviaSheet(items: items),
    );

class TriviaSheet extends StatelessWidget {
  const TriviaSheet({super.key, required this.items});

  final List<Trivia> items;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.75,
        maxWidth: 640,
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (final (index, item) in items.indexed) ...[
                      if (index > 0) const Divider(height: 32),
                      Row(
                        children: [
                          Icon(
                            Icons.lightbulb_outline,
                            color: theme.colorScheme.primary,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              item.title,
                              style: theme.textTheme.titleMedium?.copyWith(
                                color: theme.colorScheme.primary,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      TriviaBody(item.body),
                    ],
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 4, 24, 16),
              child: FilledButton.tonal(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(l10n.triviaClose),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A trivia item's text: paragraphs and `- ` bullets, with the emphasis of
/// the question format (***subject***, **bold**).
class TriviaBody extends StatelessWidget {
  const TriviaBody(this.body, {super.key});

  final String body;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.bodyLarge;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final line in body.split('\n'))
          if (line.trim().isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: line.startsWith('- ')
                  ? Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('•  ', style: style),
                        Expanded(child: _line(line.substring(2), style)),
                      ],
                    )
                  : _line(line, style),
            ),
      ],
    );
  }

  static Widget _line(String text, TextStyle? style) {
    final parsed = parseEmphasis(text);
    final note = parsed.note;
    return EmphasizedText(
      QuestionOption(
        // A trailing *(…)* stays visible here.
        text: note == null ? parsed.text : '${parsed.text} ($note)',
        marks: parsed.marks,
      ),
      style: style,
    );
  }
}
