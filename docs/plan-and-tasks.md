# Plan and tasks – TestAcer

_Last updated: 2026-11-21 · Phases 0–2 done · Next: Phase 3 (quiz)_

## Owner's answers (2026-11-21)

1. Public GitHub repository: **yes** → GitHub Pages (D-002 Accepted).
2. Email address as login name: **yes** (D-009 Accepted).
3. Admins: **only the owner**, for now.
4. Language: **Hungarian** UI and user guide, for now (D-010 Accepted).
5. Notification answering: **Igaz / Hamis**, plus a third button **Összes válasz** that opens the app with a dialog of the 4 single-select options (D-005 Accepted, changed).
6. iOS: **not in v1** (D-012).
7. All other recommendations: **accepted** – every decision in [decision-log.md](decision-log.md) is now Accepted.
8. Email link (passwordless) sign-in: **yes**, as a third method next to email + password and Google (D-013).

## Milestones

| | Milestone | Done when |
|---|---|---|
| M1 | Web MVP | invited users sign in on GitHub Pages, practise, and their progress is saved |
| M2 | Android + reminders | testers install the APK; reminders arrive in their windows and open the quick quiz |
| M3 | Answer in notification | true/false series works with the app closed; answers sync later |
| M4 | v1.0 | beta findings fixed; USER-GUIDE.md finished |

## Phase 0 – Setup

- [x] Answer the open questions (2026-11-21)
- [x] Confirm the decisions in the decision log (2026-11-21)
- [x] `.gitignore` (Flutter defaults + `data/`), `firebase.json`, Firestore rules and indexes, CI workflow (`flutter analyze` + `flutter test`) – prepared 2026-11-21
- [x] Owner: `flutter create` (Flutter 3.50.1; Android app ID `com.airdeux.testacer`), `flutter pub add crypto`, tests and validator pass – 2026-11-21
- [x] Owner: public GitHub repository [airdeux/TestAcer](https://github.com/airdeux/TestAcer), first push, CI green – 2026-11-21
- [x] Owner: Firebase project `testacer-892b3` (Spark), Email/Password + email link + Google sign-in, Firestore in the EU, first admin in `allowlist` – 2026-11-21
- [x] Owner: Firebase CLI 15.37.0, `flutterfire configure` (Android + web apps registered), Firestore rules and indexes deployed – 2026-11-21
- [x] Owner: debug SHA-1/SHA-256 fingerprints in Firebase – 2026-11-21
- [x] `firebase_core` added; CI green again (run 44926868343) – 2026-11-21

**Done when:** the empty app runs in Chrome and on an Android device, and CI is green. ✔ 2026-11-21

## Phase 1 – Question format and parser

- [x] Parser in `lib/src/question_format/` (pure Dart) following [question-format.md](question-format.md): questions, ✔ correct option, wrong options, notes, emphasis → plain text + marks
- [x] Stable question key (normalised hash)
- [x] Validation report (no / several ✔, fewer than 2 options, duplicate keys, identical options, unparsed lines)
- [x] Unit tests, incl. the real file from the git-ignored `data/` folder (skipped when it is missing, e.g. in CI)
- [x] CLI: `dart run tool/validate_questions.dart <file>`
- [x] `flutter analyze` + `flutter test` pass (checked by Claude on a temporary copy, Flutter 3.50.1); the owner repeats them after `flutter create` ([setup.md § 1](setup.md#1-flutter-project))

**Done when:** all tests pass on the real file.

## Phase 2 – Sign-in and access

- [x] Sign-in screen: email + password (sign-up, sign-in, reset password, email verification) and Google – 2026-11-21
- [x] Email link sign-in (D-013): send the link, finish sign-in on the web and in the app (`app_links`); Android App Links intent filter for `testacer-892b3.firebaseapp.com/__/auth/links` – 2026-11-21
- [x] `firebase/hosting/.well-known/assetlinks.json` with the debug key's SHA-256 – 2026-11-21 (the release key is added in Phase 5)
- [x] Hosting deployed; `https://testacer-892b3.firebaseapp.com/.well-known/assetlinks.json` serves the file – 2026-11-21
- [x] Allowlist check, "not invited yet" and "verify your e-mail" screens – 2026-11-21
- [x] Firestore rules tests against the emulator (`firebase/test`, 12 tests) and a CI job for them – 2026-11-21
- [x] Admin: invitations page (invite with role, revoke with confirmation, own address protected) – 2026-11-21
- [x] Hungarian UI texts in `lib/l10n/app_hu.arb` (D-010) – 2026-11-21
- [x] Owner: `airdeux.github.io` in the Auth authorised domains; rules-test job in CI; local analyze + tests; sign-in tried – 2026-11-21

**Done when:** an invited user can sign in all three ways on web and Android; a non-invited account cannot read anything (rules tests). ✔ 2026-11-21

## Phase 3 – Quiz (shared UI for web and Android)

- [ ] Admin import screen: pick an .md file → validate → preview → upload (batched writes); re-import keeps keys and progress
- [ ] Question-set picker (active set per user)
- [ ] Selection engine (D-006) with unit tests: skippable never chosen, wrong ones clearly more frequent, no repeats within 5
- [ ] Quiz screen: shuffled options, answer, feedback with emphasis and note, skippable toggle, next / close
- [ ] Quiz length setting: 1 / 5 / 10 / all / endless
- [ ] Progress screen: overall accuracy, questions per box, weak questions, skipped list with undo
- [ ] Offline support: Firestore persistence; progress written after each answer (debounced)

**Done when:** a 10-question quiz works on web and Android, progress persists, statistics are correct.

## Phase 4 – Web deploy → M1

- [ ] GitHub Actions workflow: `flutter build web --release --base-href /TestAcer/` → GitHub Pages
- [ ] Add `<user>.github.io` to the Firebase Auth authorised domains
- [ ] Smoke test: desktop Chrome / Edge / Firefox, mobile Chrome
- [ ] Invite the first 2–3 users

## Phase 5 – Android reminders → M2

- [ ] Notification settings: windows (days, start, end, interval), mode (open / true-false), "send a test notification now"
- [ ] Planner: next 48 slots in Europe/Budapest, pre-picked questions, `zonedSchedule` (inexact, allow while idle); unit tests incl. daylight-saving changes
- [ ] Refill triggers: app start, settings change, notification interaction, daily `workmanager` job, reboot, time-zone change
- [ ] Notification tap → deep link into the quick quiz starting with that question
- [ ] Permission flow (Android 13+) and a hint about battery optimisation
- [ ] Signed release APK; distribute via Firebase App Distribution (or a direct APK)

## Phase 6 – Answering in the notification → M3

- [ ] True/false mode: statement + **Igaz** / **Hamis** / **Összes válasz** buttons
- [ ] „Összes válasz”: open the app with a dialog of the same question (4 shuffled, single-select options), feedback with skippable toggle, **Bezár** / **Következő**
- [ ] Background handler (`@pragma('vm:entry-point')`) for Igaz / Hamis: local answer queue, local progress update, result + next statement, re-plan remaining slots
- [ ] Sync the queue to Firestore on app start (add counters, keep the later `lastAt`)
- [ ] Unit tests for the handler logic; manual tests on at least two Android devices (one Android 13+)

## Phase 7 – Beta and polish → M4

- [ ] 1–2 weeks with the testers; record findings in [qa-log.md](qa-log.md)
- [ ] Fixes; tune weights and default settings
- [ ] Accessibility (text scaling, contrast), dark mode
- [ ] Version 1.0.0; update [change-log.md](change-log.md)

## Phase 8 – User guide

- [ ] Finish [USER-GUIDE.md](../USER-GUIDE.md) in Hungarian, with screenshots (web and Android)
- [ ] Final setup and deploy instructions in the README

## Later / ideas

- iOS app (not in v1, D-012)
- Web reminders via FCM web push (needs Cloud Functions on the Blaze plan, or an external cron)
- Flashcard sets from statement-only files such as `elmelet-kerdes-valaszok.md`
- Questions with several correct answers
- Exam simulation: all 149 questions, timed, scored like the site
- Export of statistics
