import 'dart:async';

import 'package:material_ui/material_ui.dart';

import '../../l10n/app_localizations.dart';
import '../app_services.dart';
import '../auth/auth_models.dart';
import '../question_format/models.dart';
import '../questions/key_history.dart';
import '../questions/question_set_repository.dart';
import '../quiz/progress.dart';
import 'centered_panel.dart';
import 'emphasized_text.dart';

/// Statistics for one question set: how many seen, accuracy, Leitner boxes,
/// weakest questions, and the skippable list with undo.
class ProgressScreen extends StatefulWidget {
  const ProgressScreen({
    super.key,
    required this.services,
    required this.user,
    required this.questionSet,
  });

  final AppServices services;
  final AppUser user;
  final QuestionSetInfo questionSet;

  @override
  State<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends State<ProgressScreen> {
  List<Question>? _questions;
  Map<String, ItemProgress> _progress = {};
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  Future<void> _load() async {
    setState(() => _failed = false);
    try {
      final setId = widget.questionSet.id;
      final questions = await widget.services.questionSets.loadQuestions(setId);
      final progress = carryOverProgress(
        await widget.services.progress.load(widget.user.uid, setId),
        questions,
      );
      if (mounted) {
        setState(() {
          _questions = questions;
          _progress = Map.of(progress);
        });
      }
    } on Exception catch (error) {
      debugPrint('Progress load failed: $error');
      if (mounted) setState(() => _failed = true);
    }
  }

  void _undoSkippable(String key) {
    final item = (_progress[key] ?? const ItemProgress()).withSkippable(false);
    setState(() => _progress[key] = item);
    unawaited(
      widget.services.progress
          .save(widget.user.uid, widget.questionSet.id, key, item)
          .catchError((Object error) => debugPrint('Progress save failed: $error')),
    );
  }

  /// Asks for confirmation – and, when there are any, whether the skippable
  /// list goes too – then deletes the progress on this set.
  Future<void> _confirmReset(List<Question> skipped) async {
    final l10n = AppLocalizations.of(context);
    final danger = TextButton.styleFrom(
      foregroundColor: Theme.of(context).colorScheme.error,
    );
    final keepSkippable = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.resetProgress),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.resetProgressBody(widget.questionSet.title)),
            if (skipped.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(l10n.resetProgressSkippableQuestion(skipped.length)),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(l10n.cancelButton),
          ),
          if (skipped.isNotEmpty) ...[
            TextButton(
              style: danger,
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(l10n.resetKeepSkippable),
            ),
            TextButton(
              style: danger,
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(l10n.resetEverything),
            ),
          ] else
            TextButton(
              style: danger,
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(l10n.resetConfirm),
            ),
        ],
      ),
    );
    if (keepSkippable == null || !mounted) return;
    final keep = keepSkippable ? {for (final q in skipped) q.key} : <String>{};
    setState(() {
      _progress = {for (final key in keep) key: const ItemProgress(skippable: true)};
    });
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.resetDone)));
    unawaited(
      widget.services.progress
          .reset(widget.user.uid, widget.questionSet.id, keepSkippable: keep)
          .catchError((Object error) => debugPrint('Progress reset failed: $error')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final questions = _questions;
    if (_failed) {
      return CenteredPanel(
        appBar: AppBar(title: Text(l10n.progressTitle)),
        children: [
          Text(l10n.loadError, textAlign: TextAlign.center),
          const SizedBox(height: 16),
          FilledButton(onPressed: _load, child: Text(l10n.retry)),
        ],
      );
    }
    if (questions == null) return const LoadingScreen();

    final theme = Theme.of(context);
    final stats = _Stats(questions, _progress);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.progressTitle)),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text(widget.questionSet.title, style: theme.textTheme.titleLarge),
                const SizedBox(height: 8),
                Text(l10n.progressSeen(stats.seen, questions.length)),
                if (stats.answers > 0) Text(l10n.progressAccuracy(stats.accuracyPercent)),
                const SizedBox(height: 16),
                Text(l10n.progressBoxesTitle, style: theme.textTheme.titleMedium),
                const SizedBox(height: 8),
                _BoxRow(label: l10n.progressUnseen, count: stats.unseen, total: questions.length),
                for (var box = 0; box <= ItemProgress.maxBox; box++)
                  _BoxRow(
                    label: _boxLabel(l10n, box),
                    count: stats.boxes[box],
                    total: questions.length,
                  ),
                // Not in any box above, so the rows add up to all questions.
                _BoxRow(
                  label: l10n.progressSkippedRow,
                  count: stats.skipped.length,
                  total: questions.length,
                ),
                const SizedBox(height: 24),
                Text(l10n.progressWeakTitle, style: theme.textTheme.titleMedium),
                if (stats.weak.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Text(l10n.progressNoWeak),
                  ),
                for (final question in stats.weak)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: EmphasizedText(question.correct),
                    subtitle: Text(
                      l10n.progressWeakItem(
                        _progress[question.key]!.wrong,
                        _progress[question.key]!.seen,
                      ),
                    ),
                  ),
                const SizedBox(height: 24),
                Text(
                  l10n.progressSkippedTitle(stats.skipped.length),
                  style: theme.textTheme.titleMedium,
                ),
                if (stats.skipped.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Text(l10n.progressNoSkipped),
                  ),
                for (final question in stats.skipped)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: EmphasizedText(question.correct),
                    trailing: TextButton(
                      onPressed: () => _undoSkippable(question.key),
                      child: Text(l10n.undoSkippable),
                    ),
                  ),
                const SizedBox(height: 32),
                Center(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: theme.colorScheme.error,
                    ),
                    onPressed: stats.seen == 0 && stats.skipped.isEmpty
                        ? null
                        : () => _confirmReset(stats.skipped),
                    icon: const Icon(Icons.delete_outline),
                    label: Text(l10n.resetProgress),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static String _boxLabel(AppLocalizations l10n, int box) => switch (box) {
        0 => l10n.progressBox0,
        1 => l10n.progressBox1,
        2 => l10n.progressBox2,
        3 => l10n.progressBox3,
        _ => l10n.progressBox4,
      };
}

/// Numbers shown on the progress page.
class _Stats {
  _Stats(List<Question> questions, Map<String, ItemProgress> progress) {
    for (final question in questions) {
      final item = progress[question.key];
      if (item != null && item.skippable) {
        skipped.add(question);
        // Counted for „seen” and accuracy, but in no box row.
        if (item.seen > 0) {
          seen++;
          correct += item.correct;
          answers += item.correct + item.wrong;
        }
        continue;
      }
      if (item == null || item.seen == 0) {
        unseen++;
        continue;
      }
      seen++;
      correct += item.correct;
      answers += item.correct + item.wrong;
      boxes[item.box]++;
      if (item.wrong > 0) weak.add(question);
    }
    weak.sort((a, b) {
      final pa = progress[a.key]!;
      final pb = progress[b.key]!;
      final byBox = pa.box.compareTo(pb.box);
      if (byBox != 0) return byBox;
      final byWrong = pb.wrong.compareTo(pa.wrong);
      return byWrong != 0 ? byWrong : a.order.compareTo(b.order);
    });
    if (weak.length > 20) weak.removeRange(20, weak.length);
  }

  int seen = 0;
  int unseen = 0;
  int correct = 0;
  int answers = 0;
  final boxes = List<int>.filled(ItemProgress.maxBox + 1, 0);
  final weak = <Question>[];
  final skipped = <Question>[];

  int get accuracyPercent => answers == 0 ? 0 : (100 * correct / answers).round();
}

class _BoxRow extends StatelessWidget {
  const _BoxRow({required this.label, required this.count, required this.total});

  final String label;
  final int count;
  final int total;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(flex: 3, child: Text(label)),
          Expanded(
            flex: 2,
            child: LinearProgressIndicator(value: total == 0 ? 0 : count / total),
          ),
          SizedBox(width: 40, child: Text('$count', textAlign: TextAlign.end)),
        ],
      ),
    );
  }
}
