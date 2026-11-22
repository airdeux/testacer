import 'package:material_ui/material_ui.dart';

import '../../l10n/app_localizations.dart';
import '../app_services.dart';
import '../auth/auth_models.dart';
import '../questions/question_set_repository.dart';
import '../reminders/reminder_settings.dart';
import 'centered_panel.dart';

/// Reminder intervals offered in the settings, in minutes.
const reminderIntervals = [15, 30, 45, 60, 90, 120, 180, 240];

/// Android reminder settings: on/off, time windows, test notification.
/// Saved to `users/{uid}`; the home page re-plans when they change.
class ReminderSettingsScreen extends StatefulWidget {
  const ReminderSettingsScreen({
    super.key,
    required this.services,
    required this.user,
    required this.questionSet,
    required this.initial,
  });

  final AppServices services;
  final AppUser user;

  /// The active set; the test notification asks one of its questions.
  final QuestionSetInfo questionSet;
  final ReminderSettings initial;

  @override
  State<ReminderSettingsScreen> createState() => _ReminderSettingsScreenState();
}

class _ReminderSettingsScreenState extends State<ReminderSettingsScreen> {
  late ReminderSettings _saved = widget.initial;
  late ReminderSettings _settings = widget.initial.windows.isEmpty
      ? widget.initial.copyWith(windows: const [ReminderWindow.standard])
      : widget.initial;
  bool _busy = false;

  AppLocalizations get _l10n => AppLocalizations.of(context);

  bool get _valid => _settings.windows.every((window) => window.isValid);
  bool get _dirty => _settings != _saved;

  void _snack(String text) => ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(text)));

  /// Asks for the notification permission; explains if it is refused.
  Future<bool> _ensurePermission() async {
    final reminders = widget.services.reminders;
    if (await reminders.notificationsEnabled()) return true;
    final granted = await reminders.requestPermission();
    if (!granted && mounted) {
      _snack(_l10n.remindersPermissionDenied(_l10n.appTitle));
    }
    return granted;
  }

  Future<void> _setEnabled(bool value) async {
    if (value && !await _ensurePermission()) return;
    if (!mounted) return;
    setState(() => _settings = _settings.copyWith(enabled: value));
  }

  void _setWindow(int index, ReminderWindow window) => setState(() {
        _settings = _settings.copyWith(
          windows: [..._settings.windows]..[index] = window,
        );
      });

  void _addWindow() => setState(() {
        _settings = _settings.copyWith(
          windows: [..._settings.windows, ReminderWindow.standard],
        );
      });

  void _removeWindow(int index) => setState(() {
        _settings = _settings.copyWith(
          windows: [..._settings.windows]..removeAt(index),
        );
      });

  Future<void> _save() async {
    setState(() => _busy = true);
    final settings = _settings;
    try {
      await widget.services.settings.update(
        widget.user.uid,
        reminders: settings,
      );
      if (!mounted) return;
      setState(() => _saved = settings);
      _snack(_l10n.remindersSaved);
    } on Exception catch (error) {
      debugPrint('Saving reminder settings failed: $error');
      if (mounted) _snack(_l10n.loadError);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _sendTest() async {
    if (!await _ensurePermission()) return;
    setState(() => _busy = true);
    final sent = await widget.services.reminders.sendTest(
      uid: widget.user.uid,
      set: widget.questionSet,
    );
    if (!mounted) return;
    setState(() => _busy = false);
    _snack(sent ? _l10n.remindersTestSent : _l10n.remindersTestFailed);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = _l10n;
    final theme = Theme.of(context);
    final windows = _settings.windows;
    return CenteredPanel(
      appBar: AppBar(title: Text(l10n.remindersTitle)),
      children: [
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(l10n.remindersEnable),
          subtitle: Text(l10n.remindersEnableHint),
          value: _settings.enabled,
          onChanged: _busy ? null : _setEnabled,
        ),
        const SizedBox(height: 8),
        Text(l10n.remindersMode, style: theme.textTheme.labelLarge),
        const SizedBox(height: 4),
        SegmentedButton<ReminderMode>(
          segments: [
            ButtonSegment(
              value: ReminderMode.open,
              label: Text(l10n.remindersModeOpen),
              icon: const Icon(Icons.open_in_new),
            ),
            ButtonSegment(
              value: ReminderMode.trueFalse,
              label: Text(l10n.remindersModeTrueFalse),
              icon: const Icon(Icons.rule),
            ),
          ],
          selected: {_settings.mode},
          onSelectionChanged: _busy
              ? null
              : (selection) => setState(
                    () => _settings = _settings.copyWith(mode: selection.first),
                  ),
        ),
        const SizedBox(height: 4),
        Text(
          _settings.mode == ReminderMode.trueFalse
              ? l10n.remindersModeTrueFalseHint
              : l10n.remindersModeOpenHint,
          style: theme.textTheme.bodySmall,
        ),
        const SizedBox(height: 16),
        for (var i = 0; i < windows.length; i++) ...[
          _WindowCard(
            number: i + 1,
            window: windows[i],
            enabled: !_busy,
            onChanged: (window) => _setWindow(i, window),
            onRemove: windows.length > 1 ? () => _removeWindow(i) : null,
          ),
          const SizedBox(height: 12),
        ],
        TextButton.icon(
          onPressed: _busy ? null : _addWindow,
          icon: const Icon(Icons.add),
          label: Text(l10n.remindersAddWindow),
        ),
        const SizedBox(height: 4),
        Text(
          l10n.remindersTimeZoneNote,
          style: theme.textTheme.bodySmall,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        FilledButton(
          onPressed: !_busy && _valid && _dirty ? _save : null,
          child: Text(l10n.saveButton),
        ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: _busy ? null : _sendTest,
          icon: const Icon(Icons.notifications_active_outlined),
          label: Text(l10n.remindersTest),
        ),
        const SizedBox(height: 24),
        Card.outlined(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.battery_alert_outlined, color: theme.hintColor),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    l10n.remindersBatteryHint(l10n.appTitle),
                    style: theme.textTheme.bodySmall,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// One time window: days, first and last time, interval.
class _WindowCard extends StatelessWidget {
  const _WindowCard({
    required this.number,
    required this.window,
    required this.enabled,
    required this.onChanged,
    this.onRemove,
  });

  final int number;
  final ReminderWindow window;
  final bool enabled;
  final ValueChanged<ReminderWindow> onChanged;
  final VoidCallback? onRemove;

  static String dayLabel(AppLocalizations l10n, int day) => switch (day) {
        1 => l10n.dayShort1,
        2 => l10n.dayShort2,
        3 => l10n.dayShort3,
        4 => l10n.dayShort4,
        5 => l10n.dayShort5,
        6 => l10n.dayShort6,
        _ => l10n.dayShort7,
      };

  static String intervalLabel(AppLocalizations l10n, int minutes) =>
      minutes == 60
          ? l10n.everyHour
          : minutes % 60 == 0
              ? l10n.everyHours(minutes ~/ 60)
              : l10n.everyMinutes(minutes);

  Future<void> _pickTime(BuildContext context, {required bool start}) async {
    final current = start ? window.start : window.end;
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: current ~/ 60, minute: current % 60),
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
        child: child!,
      ),
    );
    if (picked == null) return;
    final minutes = picked.hour * 60 + picked.minute;
    onChanged(
      start ? window.copyWith(start: minutes) : window.copyWith(end: minutes),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final error = window.days.isEmpty
        ? l10n.remindersNoDays
        : window.end < window.start
            ? l10n.remindersEndBeforeStart
            : null;
    final intervals = {...reminderIntervals, window.everyMinutes}.toList()
      ..sort();
    return Card.outlined(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 4, 4, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    l10n.remindersWindowTitle(number),
                    style: theme.textTheme.titleSmall,
                  ),
                ),
                IconButton(
                  tooltip: l10n.remindersRemoveWindow,
                  icon: const Icon(Icons.delete_outline),
                  onPressed: enabled ? onRemove : null,
                ),
              ],
            ),
            Text(l10n.remindersDays, style: theme.textTheme.labelMedium),
            const SizedBox(height: 4),
            Wrap(
              spacing: 4,
              runSpacing: 4,
              children: [
                for (var day = 1; day <= 7; day++)
                  FilterChip(
                    label: Text(dayLabel(l10n, day)),
                    showCheckmark: false,
                    visualDensity: VisualDensity.compact,
                    selected: window.days.contains(day),
                    onSelected: enabled
                        ? (selected) => onChanged(
                              window.copyWith(
                                days: selected
                                    ? {...window.days, day}
                                    : ({...window.days}..remove(day)),
                              ),
                            )
                        : null,
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _TimeField(
                    label: l10n.remindersFrom,
                    minutes: window.start,
                    onTap: enabled ? () => _pickTime(context, start: true) : null,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _TimeField(
                    label: l10n.remindersTo,
                    minutes: window.end,
                    onTap: enabled ? () => _pickTime(context, start: false) : null,
                  ),
                ),
                const SizedBox(width: 8),
              ],
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: DropdownButtonFormField<int>(
                initialValue: window.everyMinutes,
                isExpanded: true,
                decoration: InputDecoration(
                  labelText: l10n.remindersEvery,
                  border: const OutlineInputBorder(),
                  isDense: true,
                ),
                items: [
                  for (final minutes in intervals)
                    DropdownMenuItem(
                      value: minutes,
                      child: Text(intervalLabel(l10n, minutes)),
                    ),
                ],
                onChanged: enabled
                    ? (minutes) => onChanged(window.copyWith(everyMinutes: minutes))
                    : null,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              error ?? l10n.remindersPerDay(window.perDay),
              style: theme.textTheme.bodySmall?.copyWith(
                color: error == null ? null : theme.colorScheme.error,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TimeField extends StatelessWidget {
  const _TimeField({required this.label, required this.minutes, this.onTap});

  final String label;
  final int minutes;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(4),
        child: InputDecorator(
          decoration: InputDecoration(
            labelText: label,
            border: const OutlineInputBorder(),
            isDense: true,
            suffixIcon: const Icon(Icons.schedule, size: 20),
          ),
          child: Text(formatMinutes(minutes)),
        ),
      );
}
