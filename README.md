# TestAcer

Shown to users as **Kvíz-maxoló**. A small practice-quiz app for exam preparation. First use case: the theory test of the judo 2nd dan exam (149 multiple-choice questions). One Flutter codebase builds the **web app** and the **Android app**; the Android app adds scheduled quiz reminders.

> **Status:** sign-in and the quiz (import, practice, progress) work on web and Android; every push to `main` that passes CI is published at **https://airdeux.github.io/testacer/** (Phase 4); next: Phase 5 – Android reminders. See [docs/plan-and-tasks.md](docs/plan-and-tasks.md).

## Planned features

- Sign in with email + password, an email link (passwordless) or a Google account (invite-only, fewer than 10 users at first).
- Import a question set from a Markdown file ([format](docs/question-format.md)); the first set is `../gyakorlo_teszt_osszes_valasz.md`.
- Quiz with shuffled answer options; questions you get wrong come back more often; easy / well-known questions can be marked as skippable.
- After each answer the correct answer is shown with its emphasis (subject + the words that distinguish it from the wrong answers).
- Android: recurring reminders in time windows (e.g. every hour 09:00–22:00) that open a short quiz; optionally answer straight from the notification.
- Settings and progress are stored per user and synced between web and Android.

## Proposed stack

| Area | Choice | Why (details in the decision log) |
|---|---|---|
| App (web + Android) | Flutter | one codebase, native Android build, already known by the team (D-001) |
| Sign-in | Firebase Authentication (email/password, email link, Google) | no-cost on the Spark plan (D-003, D-013) |
| Data | Cloud Firestore | free daily quota is far above what <10 users need; offline cache (D-003) |
| Reminders | on-device scheduled notifications (`flutter_local_notifications`) | no server and no paid plan needed (D-004) |
| Web hosting | GitHub Pages, deployed by GitHub Actions | free for public repositories (D-002) |
| Android distribution | Firebase App Distribution or direct APK | no Play Store needed for a small group (D-011) |

## Documentation

| Document | Purpose |
|---|---|
| [docs/project-brief.md](docs/project-brief.md) | goals, users, scope, constraints, risks |
| [docs/architecture.md](docs/architecture.md) | components, data model, quiz and reminder flows |
| [docs/plan-and-tasks.md](docs/plan-and-tasks.md) | owner's answers, milestones, phases and tasks |
| [docs/setup.md](docs/setup.md) | owner's setup steps: Flutter project, GitHub, Firebase |
| [docs/decision-log.md](docs/decision-log.md) | technical decisions and their reasons |
| [docs/question-format.md](docs/question-format.md) | the Markdown format the importer accepts |
| [docs/qa-log.md](docs/qa-log.md) | test strategy, release checklist, test results |
| [docs/change-log.md](docs/change-log.md) | changes per version |
| [USER-GUIDE.md](USER-GUIDE.md) | how to use the app (draft; finished in the last phase) |

## Planned repository layout

```
TestAcer/
├─ lib/                     Flutter app source
│  └─ src/question_format/  Markdown parser (pure Dart, no Flutter imports)
├─ test/                    unit + widget tests
├─ android/, web/           platform folders (from `flutter create`)
├─ firebase/                firestore.rules, firestore.indexes.json, emulator config
├─ tool/                    dev scripts (e.g. validate a question file)
├─ .github/workflows/       CI + web deploy to GitHub Pages
├─ docs/                    project documents
├─ README.md
└─ USER-GUIDE.md
```

Question files are **not** committed (D-008). Keep them outside the repo or in a git-ignored `data/` folder.

## Development (after the steps in docs/setup.md)

```bash
flutter pub get
flutter test                                    # parser, selection engine, planner tests
flutter run -d chrome                           # web
flutter run -d <android-device-id>              # Android
firebase emulators:start --only auth,firestore  # local backend
cd firebase; npm ci; npm test                   # Firestore rules tests
flutter build web --release --base-href /testacer/
```

Publishing: every push to `main` that passes CI is deployed to GitHub Pages by `.github/workflows/deploy-web.yml` (see docs/setup.md § 6).
