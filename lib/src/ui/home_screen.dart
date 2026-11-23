import 'package:material_ui/material_ui.dart';

import '../../l10n/app_localizations.dart';
import '../access/access_repository.dart';
import '../app_services.dart';
import '../auth/auth_models.dart';
import '../questions/question_set_repository.dart';
import '../quiz/quiz_length.dart';
import '../settings/user_settings.dart';
import 'centered_panel.dart';
import 'import_screen.dart';
import 'invitations_screen.dart';
import 'messages.dart';
import 'progress_screen.dart';
import 'quiz_screen.dart';
import 'reminder_settings_screen.dart';

/// Start page: choose the question set and quiz length, start practising,
/// see progress. Admins also import sets and manage invitations.
class HomeScreen extends StatelessWidget {
  const HomeScreen({
    super.key,
    required this.services,
    required this.user,
    required this.role,
  });

  final AppServices services;
  final AppUser user;
  final AccessRole role;

  bool get _isAdmin => role == AccessRole.admin;

  void _open(BuildContext context, Widget screen) => Navigator.of(context)
      .push(MaterialPageRoute<void>(builder: (_) => screen));

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return CenteredPanel(
      appBar: AppBar(
        title: Text(l10n.appTitle),
        actions: [
          if (_isAdmin) ...[
            IconButton(
              tooltip: l10n.importTitle,
              icon: const Icon(Icons.upload_file),
              onPressed: () => _open(context, ImportScreen(services: services)),
            ),
            IconButton(
              tooltip: l10n.invitationsTitle,
              icon: const Icon(Icons.group_add_outlined),
              onPressed: () => _open(
                context,
                InvitationsScreen(access: services.access, currentEmail: user.email),
              ),
            ),
          ],
          IconButton(
            tooltip: l10n.signOut,
            icon: const Icon(Icons.logout),
            onPressed: () async {
              // Reminders belong to the signed-in user.
              await services.reminders.clear();
              await services.auth.signOut();
            },
          ),
        ],
      ),
      children: [
        Text(
          l10n.homeGreeting(user.greetingName),
          style: Theme.of(context).textTheme.headlineSmall,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Center(child: Chip(label: Text(roleLabel(l10n, role)))),
        const SizedBox(height: 24),
        _PracticePanel(services: services, user: user, isAdmin: _isAdmin, open: _open),
      ],
    );
  }
}

class _PracticePanel extends StatefulWidget {
  const _PracticePanel({
    required this.services,
    required this.user,
    required this.isAdmin,
    required this.open,
  });

  final AppServices services;
  final AppUser user;
  final bool isAdmin;
  final void Function(BuildContext, Widget) open;

  @override
  State<_PracticePanel> createState() => _PracticePanelState();
}

class _PracticePanelState extends State<_PracticePanel> {
  late final Stream<List<QuestionSetInfo>> _sets =
      widget.services.questionSets.watchSets();
  late final Stream<UserSettings> _settings =
      widget.services.settings.watch(widget.user.uid);

  /// Latest data, for re-planning reminders and opening tapped ones.
  List<QuestionSetInfo>? _latestSets;
  QuestionSetInfo? _active;
  UserSettings? _current;
  Object? _syncedFor;

  @override
  void initState() {
    super.initState();
    widget.services.reminders.launches.addListener(_openLaunch);
  }

  @override
  void dispose() {
    widget.services.reminders.launches.removeListener(_openLaunch);
    super.dispose();
  }

  /// Re-plans the reminders when the set or the reminder settings changed,
  /// or always when [force] (progress may have changed).
  void _syncReminders({bool force = false}) {
    final active = _active;
    final settings = _current;
    final reminders = widget.services.reminders;
    if (active == null || settings == null || !reminders.supported) return;
    final key = (active.id, active.importedAt, settings.reminders);
    if (!force && key == _syncedFor) return;
    _syncedFor = key;
    reminders.sync(
      uid: widget.user.uid,
      set: active,
      settings: settings.reminders,
    );
  }

  /// Opens the quick quiz of a tapped reminder, once the sets are loaded.
  void _openLaunch() {
    final sets = _latestSets;
    if (sets == null || !mounted) return;
    final launch = widget.services.reminders.launches.take();
    if (launch == null) return;
    final set = sets.where((set) => set.id == launch.setId).firstOrNull;
    if (set == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context).reminderSetMissing)),
      );
      return;
    }
    _openQuiz(set, QuizLength.endless, startKey: launch.key);
  }

  void _openQuiz(QuestionSetInfo set, QuizLength length, {String? startKey}) {
    Navigator.of(context)
        .push(
          MaterialPageRoute<void>(
            builder: (_) => QuizScreen(
              services: widget.services,
              user: widget.user,
              questionSet: set,
              length: length,
              startKey: startKey,
            ),
          ),
        )
        .then((_) => _syncReminders(force: true));
  }

  void _afterBuild(
    List<QuestionSetInfo> sets,
    QuestionSetInfo active,
    UserSettings settings,
  ) {
    _latestSets = sets;
    _active = active;
    _current = settings;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _syncReminders();
      if (widget.services.reminders.launches.pending != null) _openLaunch();
    });
  }

  void _update({String? activeSetId, QuizLength? quizLength}) =>
      widget.services.settings.update(
        widget.user.uid,
        activeSetId: activeSetId,
        quizLength: quizLength,
      );

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return StreamBuilder<List<QuestionSetInfo>>(
      stream: _sets,
      builder: (context, setsSnapshot) {
        if (setsSnapshot.hasError) {
          return Text(l10n.loadError, textAlign: TextAlign.center);
        }
        final sets = setsSnapshot.data;
        if (sets == null) return const Center(child: CircularProgressIndicator());
        if (sets.isEmpty) {
          return Text(
            widget.isAdmin
                ? '${l10n.noQuestionSets} ${l10n.noQuestionSetsAdmin}'
                : l10n.noQuestionSets,
            textAlign: TextAlign.center,
          );
        }
        return StreamBuilder<UserSettings>(
          stream: _settings,
          builder: (context, settingsSnapshot) {
            final settings = settingsSnapshot.data ?? const UserSettings();
            final active = sets.firstWhere(
              (set) => set.id == settings.activeSetId,
              orElse: () => sets.first,
            );
            if (settingsSnapshot.hasData) _afterBuild(sets, active, settings);
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (sets.length > 1)
                  InputDecorator(
                    decoration: InputDecoration(
                      labelText: l10n.questionSetLabel,
                      border: const OutlineInputBorder(),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        isExpanded: true,
                        isDense: true,
                        value: active.id,
                        items: [
                          for (final set in sets)
                            DropdownMenuItem(value: set.id, child: Text(set.title)),
                        ],
                        onChanged: (id) => _update(activeSetId: id),
                      ),
                    ),
                  )
                else
                  Text(
                    active.title,
                    style: theme.textTheme.titleMedium,
                    textAlign: TextAlign.center,
                  ),
                const SizedBox(height: 4),
                Text(
                  l10n.questionCount(active.questionCount),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                Text(l10n.quizLengthLabel, style: theme.textTheme.labelLarge),
                const SizedBox(height: 8),
                SegmentedButton<QuizLength>(
                  showSelectedIcon: false,
                  segments: [
                    for (final length in QuizLength.values)
                      ButtonSegment(
                        value: length,
                        label: Text(_lengthLabel(l10n, length)),
                        tooltip: length == QuizLength.endless
                            ? l10n.quizLengthEndless
                            : null,
                      ),
                  ],
                  selected: {settings.quizLength},
                  onSelectionChanged: (selection) =>
                      _update(quizLength: selection.single),
                ),
                const SizedBox(height: 20),
                FilledButton.icon(
                  onPressed: () => _openQuiz(active, settings.quizLength),
                  icon: const Icon(Icons.play_arrow),
                  label: Text(l10n.startQuiz),
                ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  // Progress may have been reset there: re-plan reminders.
                  onPressed: () => Navigator.of(context)
                      .push(
                        MaterialPageRoute<void>(
                          builder: (_) => ProgressScreen(
                            services: widget.services,
                            user: widget.user,
                            questionSet: active,
                          ),
                        ),
                      )
                      .then((_) => _syncReminders(force: true)),
                  icon: const Icon(Icons.insights),
                  label: Text(l10n.progressTitle),
                ),
                if (widget.services.reminders.supported) ...[
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    onPressed: () => widget.open(
                      context,
                      ReminderSettingsScreen(
                        services: widget.services,
                        user: widget.user,
                        questionSet: active,
                        initial: settings.reminders,
                      ),
                    ),
                    icon: const Icon(Icons.notifications_outlined),
                    label: Text(l10n.remindersTitle),
                  ),
                ],
              ],
            );
          },
        );
      },
    );
  }

  static String _lengthLabel(AppLocalizations l10n, QuizLength length) =>
      switch (length) {
        QuizLength.all => l10n.quizLengthAll,
        QuizLength.endless => '∞',
        _ => '${length.count}',
      };
}
