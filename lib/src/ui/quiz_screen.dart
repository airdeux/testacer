import 'dart:async';
import 'dart:math';

import 'package:material_ui/material_ui.dart';

import '../../l10n/app_localizations.dart';
import '../app_services.dart';
import '../auth/auth_models.dart';
import '../question_format/models.dart';
import '../questions/key_history.dart';
import '../questions/question_set_repository.dart';
import '../quiz/progress.dart';
import '../quiz/quiz_clock.dart';
import '../quiz/quiz_length.dart';
import '../quiz/quiz_session.dart';
import 'centered_panel.dart';
import 'emphasized_text.dart';
import 'trivia_sheet.dart';

/// Colours for right and wrong answers.
const _correctColor = Color(0xFF2E7D32);

/// One quiz run over the chosen question set.
class QuizScreen extends StatefulWidget {
  const QuizScreen({
    super.key,
    required this.services,
    required this.user,
    required this.questionSet,
    required this.length,
    this.startKey,
    this.random,
    this.now,
  });

  final AppServices services;
  final AppUser user;
  final QuestionSetInfo questionSet;
  final QuizLength length;

  /// The question to start with (from a tapped reminder).
  final String? startKey;

  /// Fixed in tests for predictable shuffling.
  final Random? random;

  /// The clock of the quiz timer; fixed in tests.
  final DateTime Function()? now;

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  QuizSession? _session;
  bool _loading = true;
  List<Trivia> _trivia = const [];
  bool _failed = false;
  bool _finished = false;
  late final QuizClock _clock = QuizClock(now: widget.now);

  @override
  void initState() {
    super.initState();
    unawaited(_start());
  }

  Future<void> _start() async {
    setState(() {
      _loading = true;
      _failed = false;
      _finished = false;
    });
    try {
      final setId = widget.questionSet.id;
      final questions = await widget.services.questionSets.loadQuestions(setId);
      final progress = carryOverProgress(
        await widget.services.progress.load(widget.user.uid, setId),
        questions,
      );
      // Optional: a set without trivia, or a failed read, just shows none.
      _trivia = await widget.services.questionSets
          .loadTrivia(setId)
          .catchError((Object _) => const <Trivia>[]);
      final session = QuizSession(
        questions: questions,
        progress: progress,
        length: widget.length,
        firstKey: widget.startKey,
        random: widget.random,
      );
      if (!mounted) return;
      setState(() {
        _session = session;
        _finished = !session.next();
        _loading = false;
      });
      // The timer runs from the first question to the last answer.
      if (!_finished) _clock.start();
    } on Exception catch (error) {
      debugPrint('Quiz load failed: $error');
      if (mounted) {
        setState(() {
          _loading = false;
          _failed = true;
        });
      }
    }
  }

  void _save(String key, ItemProgress item) {
    // Not awaited: offline, Firestore completes the write only on reconnect.
    unawaited(
      widget.services.progress
          .save(widget.user.uid, widget.questionSet.id, key, item)
          .catchError((Object error) => debugPrint('Progress save failed: $error')),
    );
  }

  void _answer(int index) {
    final session = _session!;
    final item = session.answer(index);
    final question = session.current!.question;
    _save(question.key, item);
    final total = session.total;
    setState(() {
      if (total != null && session.number >= total) _clock.stop();
    });
    // D-016: trivia whose keywords appear in the correct answer pop up.
    final matching = [
      for (final item in _trivia)
        if (item.matches(question.correct.text)) item,
    ];
    if (matching.isNotEmpty) unawaited(showTrivia(context, matching));
  }

  void _setSkippable(bool value) {
    final session = _session!;
    final key = session.current!.question.key;
    _save(key, session.setSkippable(key, value));
    setState(() {});
  }

  void _next() => setState(() {
        _finished = !_session!.next();
        if (_finished) _clock.stop();
      });

  void _close() {
    if ((_session?.answered ?? 0) > 0 && !_finished) {
      setState(() {
        _finished = true;
        _clock.stop();
      });
    } else {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final session = _session;
    if (_loading) return const LoadingScreen();
    if (_failed || session == null) {
      return CenteredPanel(
        appBar: AppBar(title: Text(widget.questionSet.title)),
        children: [
          Text(l10n.loadError, textAlign: TextAlign.center),
          const SizedBox(height: 16),
          FilledButton(onPressed: _start, child: Text(l10n.retry)),
        ],
      );
    }
    if (_finished) return _summary(l10n, session);

    final current = session.current!;
    final total = session.total;
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          tooltip: l10n.closeQuiz,
          icon: const Icon(Icons.close),
          onPressed: _close,
        ),
        title: Text(
          total == null
              ? l10n.quizQuestionEndless(session.number)
              : l10n.quizQuestionOf(session.number, total),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: _ElapsedTime(clock: _clock),
          ),
        ],
        bottom: total == null
            ? null
            : PreferredSize(
                preferredSize: const Size.fromHeight(4),
                child: LinearProgressIndicator(value: session.number / total),
              ),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text(
                  current.question.prompt ?? l10n.defaultPrompt,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 12),
                for (var i = 0; i < current.options.length; i++)
                  _OptionCard(
                    letter: String.fromCharCode(65 + i),
                    option: current.options[i],
                    state: _optionState(current, i),
                    onTap: current.isAnswered ? null : () => _answer(i),
                  ),
                if (current.isAnswered) ...[
                  // Right below the options, so it is usually on screen
                  // without scrolling; the feedback follows.
                  FilledButton(
                    onPressed: _next,
                    child: Text(
                      total != null && session.number >= total
                          ? l10n.finishQuiz
                          : l10n.nextQuestion,
                    ),
                  ),
                  _Feedback(
                    current: current,
                    skippable:
                        session.progress[current.question.key]?.skippable ?? false,
                    onSkippable: _setSkippable,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _summary(AppLocalizations l10n, QuizSession session) {
    final nothingAsked = session.answered == 0;
    return CenteredPanel(
      appBar: AppBar(title: Text(widget.questionSet.title)),
      children: [
        Text(
          l10n.summaryTitle,
          style: Theme.of(context).textTheme.headlineMedium,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        Text(
          nothingAsked
              ? (session.total == 0 ? l10n.allSkipped : l10n.summaryNothingAsked)
              : l10n.summaryScore(session.correctAnswers, session.answered),
          style: Theme.of(context).textTheme.titleMedium,
          textAlign: TextAlign.center,
        ),
        if (!nothingAsked) ...[
          const SizedBox(height: 8),
          Text(
            l10n.summaryTime(formatElapsed(_clock.elapsed)),
            textAlign: TextAlign.center,
          ),
        ],
        const SizedBox(height: 24),
        FilledButton.icon(
          onPressed: _start,
          icon: const Icon(Icons.replay),
          label: Text(l10n.newRound),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.backButton),
        ),
      ],
    );
  }

  static _OptionState _optionState(CurrentQuestion current, int index) {
    if (!current.isAnswered) return _OptionState.open;
    if (index == current.correctIndex) return _OptionState.correct;
    if (index == current.chosenIndex) return _OptionState.wrongChoice;
    return _OptionState.other;
  }
}

enum _OptionState { open, correct, wrongChoice, other }

/// The quiz timer (`hh:mm:ss`), updated while the clock runs.
class _ElapsedTime extends StatefulWidget {
  const _ElapsedTime({required this.clock});

  final QuizClock clock;

  @override
  State<_ElapsedTime> createState() => _ElapsedTimeState();
}

class _ElapsedTimeState extends State<_ElapsedTime> {
  late final Timer _ticker;
  String _shown = '';

  String get _text => formatElapsed(widget.clock.elapsed);

  @override
  void initState() {
    super.initState();
    // Checked a few times a second so no second is skipped; rebuilt only
    // when the shown text changes.
    _ticker = Timer.periodic(const Duration(milliseconds: 250), (_) {
      if (widget.clock.running && _text != _shown) setState(() {});
    });
  }

  @override
  void dispose() {
    _ticker.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _shown = _text;
    return Tooltip(
      message: AppLocalizations.of(context).elapsedTime,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.timer_outlined, size: 20),
          const SizedBox(width: 4),
          Text(
            _shown,
            style: const TextStyle(fontFeatures: [FontFeature.tabularFigures()]),
          ),
        ],
      ),
    );
  }
}

class _OptionCard extends StatelessWidget {
  const _OptionCard({
    required this.letter,
    required this.option,
    required this.state,
    required this.onTap,
  });

  final String letter;
  final QuestionOption option;
  final _OptionState state;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final (Color border, Color? background, IconData? icon) = switch (state) {
      _OptionState.open => (scheme.outline, null, null),
      _OptionState.correct =>
        (_correctColor, _correctColor.withValues(alpha: 0.12), Icons.check_circle),
      _OptionState.wrongChoice =>
        (scheme.error, scheme.error.withValues(alpha: 0.12), Icons.cancel),
      _OptionState.other => (scheme.outlineVariant, null, null),
    };
    final note = state == _OptionState.open ? null : option.note;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: background ?? Colors.transparent,
        shape: RoundedRectangleBorder(
          side: BorderSide(color: border, width: state == _OptionState.open ? 1 : 2),
          borderRadius: BorderRadius.circular(12),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(radius: 13, child: Text(letter)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(option.text),
                      if (note != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            note,
                            style: const TextStyle(fontStyle: FontStyle.italic),
                          ),
                        ),
                    ],
                  ),
                ),
                if (icon != null) ...[
                  const SizedBox(width: 8),
                  Icon(icon, color: border),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Feedback extends StatelessWidget {
  const _Feedback({
    required this.current,
    required this.skippable,
    required this.onSkippable,
  });

  final CurrentQuestion current;
  final bool skippable;
  final ValueChanged<bool> onSkippable;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final correct = current.isCorrect;
    return Card(
      margin: const EdgeInsets.only(top: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              correct ? l10n.answerCorrect : l10n.answerWrong,
              style: theme.textTheme.titleMedium?.copyWith(
                color: correct ? _correctColor : theme.colorScheme.error,
              ),
            ),
            const SizedBox(height: 8),
            Text(l10n.correctAnswerLabel, style: theme.textTheme.labelLarge),
            const SizedBox(height: 4),
            EmphasizedText(current.question.correct),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(l10n.markSkippable),
              value: skippable,
              onChanged: onSkippable,
            ),
          ],
        ),
      ),
    );
  }
}
