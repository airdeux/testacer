import 'package:material_ui/material_ui.dart';

import '../../l10n/app_localizations.dart';
import '../app_services.dart';
import '../import/file_picker_service.dart';
import '../question_format/question_format.dart';
import '../questions/question_set_repository.dart';
import 'emphasized_text.dart';

/// Admin page: choose a Markdown question file, check it, and import it as a
/// new set or over an existing one.
class ImportScreen extends StatefulWidget {
  const ImportScreen({super.key, required this.services});

  final AppServices services;

  @override
  State<ImportScreen> createState() => _ImportScreenState();
}

class _ImportScreenState extends State<ImportScreen> {
  final _title = TextEditingController();
  late final Stream<List<QuestionSetInfo>> _sets =
      widget.services.questionSets.watchSets();
  PickedTextFile? _file;
  ParseResult? _result;
  bool _readError = false;
  String? _targetId;
  bool _busy = false;

  static const _shownIssues = 20;

  @override
  void dispose() {
    _title.dispose();
    super.dispose();
  }

  Future<void> _pick() async {
    PickedTextFile? file;
    try {
      file = await widget.services.filePicker.pickMarkdown();
    } on FormatException {
      setState(() => _readError = true);
      return;
    }
    if (file == null) return;
    final result = parseQuestionSet(file.text);
    setState(() {
      _readError = false;
      _file = file;
      _result = result;
      _title.text = result.questionSet.title ??
          file!.name.replaceFirst(RegExp(r'\.(md|txt)$'), '');
    });
  }

  Future<void> _import() async {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final questions = _result!.questionSet.questions;
    setState(() => _busy = true);
    try {
      await widget.services.questionSets.importSet(
        setId: _targetId,
        title: _title.text.trim(),
        sourceFile: _file!.name,
        questions: questions,
        trivia: _result!.questionSet.trivia,
      );
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.importDone(questions.length))),
      );
      navigator.pop();
    } on Exception catch (error) {
      debugPrint('Import failed: $error');
      messenger.showSnackBar(SnackBar(content: Text(l10n.errorUnknown)));
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final result = _result;
    final questions = result?.questionSet.questions ?? const [];
    final canImport = result != null &&
        !result.hasErrors &&
        questions.isNotEmpty &&
        _title.text.trim().isNotEmpty &&
        !_busy;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.importTitle)),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                OutlinedButton.icon(
                  onPressed: _busy ? null : _pick,
                  icon: const Icon(Icons.upload_file),
                  label: Text(l10n.pickFile),
                ),
                if (_readError)
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Text(
                      l10n.importReadError,
                      style: TextStyle(color: theme.colorScheme.error),
                    ),
                  ),
                if (result != null) ...[
                  const SizedBox(height: 16),
                  Text(l10n.importFileLabel(_file!.name)),
                  Text(l10n.questionCount(questions.length)),
                  if (result.questionSet.trivia.isNotEmpty)
                    Text(l10n.importTriviaCount(result.questionSet.trivia.length)),
                  const SizedBox(height: 16),
                  Text(l10n.importIssuesTitle, style: theme.textTheme.titleMedium),
                  const SizedBox(height: 4),
                  if (result.issues.isEmpty) Text(l10n.importNoIssues),
                  for (final issue in result.issues.take(_shownIssues))
                    Text(
                      issue.toString(),
                      style: TextStyle(
                        color: issue.level == IssueLevel.error
                            ? theme.colorScheme.error
                            : theme.colorScheme.tertiary,
                      ),
                    ),
                  if (result.issues.length > _shownIssues)
                    Text(l10n.importMoreIssues(result.issues.length - _shownIssues)),
                  if (result.hasErrors)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        l10n.importHasErrors,
                        style: TextStyle(color: theme.colorScheme.error),
                      ),
                    ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _title,
                    onChanged: (_) => setState(() {}),
                    decoration: InputDecoration(
                      labelText: l10n.importTitleLabel,
                      border: const OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  StreamBuilder<List<QuestionSetInfo>>(
                    stream: _sets,
                    builder: (context, snapshot) {
                      final sets = snapshot.data ?? const <QuestionSetInfo>[];
                      return InputDecorator(
                        decoration: InputDecoration(
                          labelText: l10n.importTargetLabel,
                          helperText: l10n.importReplaceNote,
                          helperMaxLines: 2,
                          border: const OutlineInputBorder(),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String?>(
                            isExpanded: true,
                            isDense: true,
                            value: sets.any((s) => s.id == _targetId) ? _targetId : null,
                            items: [
                              DropdownMenuItem(child: Text(l10n.importTargetNew)),
                              for (final set in sets)
                                DropdownMenuItem(value: set.id, child: Text(set.title)),
                            ],
                            onChanged: (id) => setState(() => _targetId = id),
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: canImport ? _import : null,
                    child: Text(l10n.importButton),
                  ),
                  if (_busy) const LinearProgressIndicator(),
                  const SizedBox(height: 24),
                  if (questions.isNotEmpty) ...[
                    Text(l10n.importPreviewTitle, style: theme.textTheme.titleMedium),
                    for (final question in questions.take(3))
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: Text('${question.order}.'),
                        title: EmphasizedText(question.correct),
                        subtitle: Text(question.wrong.map((o) => o.text).join('\n')),
                      ),
                  ],
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
