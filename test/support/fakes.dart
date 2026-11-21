import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:testacer/l10n/app_localizations.dart';
import 'package:testacer/src/access/access_repository.dart';
import 'package:testacer/src/auth/auth_models.dart';
import 'package:testacer/src/auth/auth_service.dart';
import 'package:testacer/src/auth/email_link_store.dart';
import 'package:testacer/src/localization.dart';
import 'package:testacer/src/app_services.dart';
import 'package:testacer/src/auth/email_link_controller.dart';
import 'package:testacer/src/import/file_picker_service.dart';
import 'package:testacer/src/question_format/question_format.dart';
import 'package:testacer/src/questions/question_set_repository.dart';
import 'package:testacer/src/quiz/progress.dart';
import 'package:testacer/src/quiz/progress_repository.dart';
import 'package:testacer/src/quiz/quiz_length.dart';
import 'package:testacer/src/reminders/reminder_notifications.dart';
import 'package:testacer/src/reminders/reminder_service.dart';
import 'package:testacer/src/reminders/reminder_settings.dart';
import 'package:testacer/src/settings/user_settings.dart';

/// Hungarian texts, for finding widgets by their label.
final AppLocalizations hu = lookupAppLocalizations(const Locale('hu'));

/// Wraps [child] in a localised MaterialApp.
Widget localized(Widget child) => MaterialApp(
      locale: const Locale('hu'),
      localizationsDelegates: appLocalizationsDelegates,
      supportedLocales: appSupportedLocales,
      home: child,
    );

/// Scrolls [finder] into view, then taps it.
Future<void> tapVisible(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

AppUser testUser({
  String email = 'tanulo@example.com',
  bool emailVerified = true,
  bool usesPassword = false,
  String? displayName = 'Teszt Elek',
}) =>
    AppUser(
      uid: 'uid-$email',
      email: email,
      displayName: displayName,
      emailVerified: emailVerified,
      usesPassword: usesPassword,
    );

/// Records calls; [nextFailure] makes the next call throw.
class FakeAuthService implements AuthService {
  final _users = StreamController<AppUser?>.broadcast();
  final calls = <String>[];
  AuthFailure? nextFailure;
  bool verifiedOnRefresh = false;

  void emit(AppUser? user) => _users.add(user);

  Future<void> _call(String name) async {
    calls.add(name);
    final failure = nextFailure;
    nextFailure = null;
    if (failure != null) throw failure;
  }

  @override
  Stream<AppUser?> userChanges() => _users.stream;

  @override
  Future<void> signInWithGoogle() => _call('google');

  @override
  Future<void> signInWithPassword(String email, String password) =>
      _call('password:$email');

  @override
  Future<void> registerWithPassword(String email, String password) =>
      _call('register:$email');

  @override
  Future<void> sendPasswordReset(String email) => _call('reset:$email');

  @override
  Future<void> sendSignInLink(String email) => _call('sendLink:$email');

  @override
  bool isSignInLink(String link) => link.contains('mode=signIn');

  @override
  Future<void> signInWithLink(String email, String link) =>
      _call('linkSignIn:$email');

  @override
  Future<void> sendEmailVerification() => _call('verify');

  @override
  Future<bool> refreshEmailVerified() async {
    await _call('refresh');
    return verifiedOnRefresh;
  }

  @override
  Future<void> signOut() => _call('signOut');
}

class FakeEmailLinkStore implements EmailLinkStore {
  String? email;

  @override
  Future<String?> read() async => email;

  @override
  Future<void> write(String email) async => this.email = email;

  @override
  Future<void> clear() async => email = null;
}

class FakeAccessRepository implements AccessRepository {
  final roles = StreamController<AccessRole?>.broadcast();
  final invitations = StreamController<List<Invitation>>.broadcast();
  final calls = <String>[];

  @override
  Stream<AccessRole?> watchRole(String email) => roles.stream;

  @override
  Stream<List<Invitation>> watchInvitations() => invitations.stream;

  @override
  Future<void> invite(String email, AccessRole role) async =>
      calls.add('invite:$email:${role.name}');

  @override
  Future<void> revoke(String email) async => calls.add('revoke:$email');
}

/// A value whose stream emits the current value first, then every change.
class Latest<T> {
  Latest(this._value);

  T _value;
  final _changes = StreamController<T>.broadcast();

  T get value => _value;

  set value(T value) {
    _value = value;
    _changes.add(value);
  }

  Stream<T> get stream async* {
    yield _value;
    yield* _changes.stream;
  }
}

class FakeQuestionSetRepository implements QuestionSetRepository {
  final sets = Latest<List<QuestionSetInfo>>(const []);
  final questions = <String, List<Question>>{};
  final imports = <String>[];

  /// Adds a set with [items] and returns its info.
  QuestionSetInfo add(String id, String title, List<Question> items) {
    final info = QuestionSetInfo(id: id, title: title, questionCount: items.length);
    questions[id] = items;
    sets.value = [...sets.value, info];
    return info;
  }

  @override
  Stream<List<QuestionSetInfo>> watchSets() => sets.stream;

  @override
  Future<List<Question>> loadQuestions(String setId) async => questions[setId] ?? const [];

  @override
  Future<String> importSet({
    String? setId,
    required String title,
    required String sourceFile,
    required List<Question> questions,
  }) async {
    final id = setId ?? 'set${sets.value.length + 1}';
    imports.add('$id:$title:$sourceFile:${questions.length}');
    this.questions[id] = questions;
    return id;
  }
}

class FakeProgressRepository implements ProgressRepository {
  final data = <String, Map<String, ItemProgress>>{};
  final saves = <String>[];

  @override
  Future<Map<String, ItemProgress>> load(String uid, String setId) async =>
      Map.of(data[setId] ?? const {});

  @override
  Future<void> save(String uid, String setId, String key, ItemProgress item) async {
    (data[setId] ??= {})[key] = item;
    saves.add('$setId:$key:box${item.box}:skip${item.skippable}');
  }
}

class FakeUserSettingsRepository implements UserSettingsRepository {
  final settings = Latest<UserSettings>(const UserSettings());

  @override
  Stream<UserSettings> watch(String uid) => settings.stream;

  @override
  Future<void> update(
    String uid, {
    String? activeSetId,
    QuizLength? quizLength,
    ReminderSettings? reminders,
  }) async {
    final current = settings.value;
    settings.value = UserSettings(
      activeSetId: activeSetId ?? current.activeSetId,
      quizLength: quizLength ?? current.quizLength,
      reminders: reminders ?? current.reminders,
    );
  }
}

class FakeFilePicker implements FilePickerService {
  PickedTextFile? next;
  bool notText = false;

  @override
  Future<PickedTextFile?> pickMarkdown() async {
    if (notText) throw const FormatException('not UTF-8');
    return next;
  }
}

/// Records what the screens ask of the reminders.
class FakeReminders implements Reminders {
  @override
  bool supported = true;

  @override
  final launches = ReminderLaunches();

  final syncs = <(String setId, ReminderSettings settings)>[];
  int tests = 0;
  int clears = 0;
  bool permission = true;
  bool enabled = true;

  @override
  Future<void> sync({
    required String uid,
    required QuestionSetInfo set,
    required ReminderSettings settings,
  }) async =>
      syncs.add((set.id, settings));

  @override
  Future<void> replanFromStore() async {}

  @override
  Future<bool> sendTest({
    required String uid,
    required QuestionSetInfo set,
  }) async {
    tests++;
    return true;
  }

  @override
  Future<bool> requestPermission() async => enabled = permission;

  @override
  Future<bool> notificationsEnabled() async => enabled;

  @override
  Future<void> clear() async => clears++;
}

/// Records scheduled and shown notifications.
class FakeReminderNotifications implements ReminderNotifications {
  final scheduled = <ReminderNotice>[];
  final shown = <ReminderNotice>[];
  ReminderLaunch? launch;
  void Function(ReminderLaunch)? onTap;

  @override
  Future<void> initialize({void Function(ReminderLaunch launch)? onTap}) async =>
      this.onTap = onTap;

  @override
  Future<ReminderLaunch?> launchedBy() async => launch;

  @override
  Future<bool> requestPermission() async => true;

  @override
  Future<bool> areEnabled() async => true;

  @override
  Future<void> schedule(List<ReminderNotice> notices) async {
    scheduled
      ..clear()
      ..addAll(notices);
  }

  @override
  Future<void> cancelScheduled() async => scheduled.clear();

  @override
  Future<void> showNow(ReminderNotice notice) async => shown.add(notice);
}

/// All fakes, plus the [AppServices] made of them.
class TestServices {
  final auth = FakeAuthService();
  final access = FakeAccessRepository();
  final emailLinkStore = FakeEmailLinkStore();
  final questionSets = FakeQuestionSetRepository();
  final progress = FakeProgressRepository();
  final settings = FakeUserSettingsRepository();
  final filePicker = FakeFilePicker();
  final reminders = FakeReminders();

  late final AppServices services = AppServices(
    auth: auth,
    access: access,
    emailLinks: EmailLinkController(
      auth: auth,
      store: emailLinkStore,
      links: const Stream<Uri>.empty(),
    ),
    questionSets: questionSets,
    progress: progress,
    settings: settings,
    filePicker: filePicker,
    reminders: reminders,
  );
}

/// Questions parsed from Markdown, for screen tests.
List<Question> sampleQuestions() => parseQuestionSet('''
## 1.

1. ✔ A ***„Yoshi”*** jelentése, **fojtasd.**
2. A „Yoshi” jelentése, állj.
3. A „Yoshi” jelentése, rajta.
4. A „Yoshi” jelentése, ne mozdulj.

## 2.

1. ✔ A 2. kyu övszíne **kék.**
2. A 2. kyu övszíne citromsárga.
3. A 2. kyu övszíne barna.
4. A 2. kyu övszíne zöld. *(megjegyzés)*

## 3.

1. ✔ A ***„Tatami”*** a gyakorló szőnyeget jelenti.
2. A „Judoka” a gyakorló szőnyeget jelenti.
3. A „Dojo” a gyakorló szőnyeget jelenti.
4. A „Rei” a gyakorló szőnyeget jelenti.
''').questionSet.questions;
