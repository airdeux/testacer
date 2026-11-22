# Plan and tasks – TestAcer

_Last updated: 2026-11-21 · Phases 0–3 done · Phase 4: web app live at https://airdeux.github.io/testacer/, owner checks pending · Phase 5 (Android reminders) built, waiting for the owner's device test · Phase 6 (answering in the notification) built, waiting for the device test · Google Play developer account in verification_

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

- [x] Admin import screen: pick an .md file → validate → preview → upload (batched writes); re-import keeps keys and progress, removes questions no longer in the file – 2026-11-21
- [x] Question-set picker (active set per user, synced in `users/{uid}`) – 2026-11-21
- [x] Selection engine (D-006) with unit tests: skippable never chosen, box 0 ≈ 16× as likely as box 4, no repeats within 5 (none at all within a fixed-length quiz) – 2026-11-21
- [x] Quiz screen: shuffled options (A–D), answer, feedback with emphasis and note, skippable switch, next / result, close (endless mode shows the score so far) – 2026-11-21
- [x] Quiz length setting: 1 / 5 / 10 / Mind / ∞ – 2026-11-21
- [x] Progress screen: seen count, accuracy, questions per box, weakest 20, skippable list with undo – 2026-11-21
- [x] Offline support: Firestore persistence also on the web; each answer is saved at once without waiting for the server – 2026-11-21
- [x] Owner: import `gyakorlo_teszt_osszes_valasz.md` in the app, do a 10-question quiz on web and Android, check the progress page – 2026-11-21

**Done when:** a 10-question quiz works on web and Android, progress persists, statistics are correct. ✔ 2026-11-21

## Phase 4 – Web deploy → M1

- [x] GitHub Actions workflow `deploy-web.yml`: after CI passes on `main`, `flutter build web --release --base-href /testacer/` → GitHub Pages (also by hand) – 2026-11-21
- [x] Web shell: Hungarian language tag, description and theme colour in `index.html` / `manifest.json` – 2026-11-21
- [x] Add `airdeux.github.io` to the Firebase Auth authorised domains (done in Phase 2) – 2026-11-21
- [x] Owner: workflow file in place, Pages on (Source: GitHub Actions), push – first deploy green (Deploy web #1) – 2026-11-21
- [x] Live site check (Claude, built-in browser): sign-in screen renders; all app files 200 under `/TestAcer/`; title „Test Acer”, `lang=hu` – 2026-11-21
- [x] Owner: repository renamed `TestAcer` → `testacer` for a lower-case address; web and Hosting redeployed; checked by Claude – 2026-11-21
- [ ] Smoke test: desktop Chrome / Edge / Firefox, mobile Chrome
- [ ] Invite the first 2–3 users

## Phase 5 – Android reminders → M2

- [x] Notification settings: on/off, windows (days, first/last time, interval 15 min – 4 h), "send a test notification now"; synced in `users/{uid}.settings.notifications` (the mode choice comes with Phase 6) – 2026-11-21
- [x] Planner: next 48 slots in Europe/Budapest, pre-picked questions, `zonedSchedule` (inexact, allow while idle); unit tests incl. daylight-saving changes – 2026-11-21
- [x] Refill triggers: home page, set or settings change, after each quiz, `workmanager` job every 12 h (from a snapshot on the phone), reboot and app update (plugin's boot receiver); sign-out cancels; time-zone change not needed (fixed zone) – 2026-11-21
- [x] Notification tap → endless quick quiz starting with that question (also when the tap starts the app) – 2026-11-21
- [x] Permission flow (Android 13+) and a hint about battery optimisation – 2026-11-21
- [x] Release signing config (`android/key.properties`, falls back to the debug key) and distribution steps (docs/setup.md § 7) – 2026-11-21
- [ ] Owner: try reminders on the phone (debug build, docs/setup.md § 7.1)
- [x] Owner: release key created; its SHA-256 added to `assetlinks.json` by Claude – 2026-11-22
- [x] Owner: release key's SHA-1 + SHA-256 in Firebase, `flutterfire configure`, `firebase deploy --only hosting` (§ 7.2); checked by Claude: live `assetlinks.json` lists the debug and release SHA-256, `google-services.json` has Android OAuth clients for both SHA-1 – 2026-11-22
- [x] Owner: release APK 1.0.0 (1) built (54 MB, all ABIs) and distributed via Firebase App Distribution to the owner – 2026-11-22
- [x] Owner: App Distribution install shows Android and Play Protect warnings → testers get the app from Google Play internal testing instead (D-014) – 2026-11-22
- [ ] Owner: Google Play developer account (personal, USD 25, identity verification) and the app „Kvíz-maxoló” (docs/setup.md § 7.3)
- [ ] Owner: first app bundle (`flutter build appbundle --release`) to Internal testing
- [ ] Owner: app signing key's SHA-1 + SHA-256 to Firebase; SHA-256 to Claude for `assetlinks.json`; Hosting deploy
- [ ] Owner: install from Play on your phone; check sign-in (Google, e-mail link opens the app) and reminders
- [ ] Owner: tester e-mail list + opt-in link; invite the same addresses in the app

## Phase 6 – Answering in the notification → M3

- [x] Mode switch in **Emlékeztetők**: „Kvíz megnyitása” / „Igaz / Hamis” – 2026-11-22
- [x] True/false mode: statement (correct option or a wrong one, half and half) + **Igaz** / **Hamis** / **Összes válasz** buttons – 2026-11-22
- [x] „Összes válasz”: opens the app on the quick quiz starting with the same question (4 shuffled, single-select options, feedback with emphasis, note and skippable toggle, **Következő**, ✕ to close) – the quiz page instead of a separate dialog (D-005 note) – 2026-11-22
- [x] Background handler (`@pragma('vm:entry-point')`) for Igaz / Hamis: local progress update, answer queue, result + next statement in the same notification (quiet), re-plan remaining slots – 2026-11-22
- [x] Sync the queue to Firestore on the next sync (home page, after a quiz): answers replayed on the stored record, a later `lastAt` kept; re-queued if Firestore cannot be read – 2026-11-22
- [x] Unit tests for the handler logic (128 tests in all) – 2026-11-22
- [ ] Owner: manual tests on at least two Android devices (one Android 13+): Igaz / Hamis with the app closed, in the background and open; Összes válasz; answers appear in Haladás after opening the app

## Phase 7 – Beta and polish → M4

- [ ] 1–2 weeks with the testers; record findings in [qa-log.md](qa-log.md)
- [ ] Fixes; tune weights and default settings
- [x] App icon instead of the Flutter logo: belt-check mark on blue; Android launcher (legacy, adaptive, themed), status-bar icon, web icons, Play listing icon – 2026-11-22
- [ ] Accessibility (text scaling, contrast), dark mode
- [ ] Watch `workmanager_android` for a Built-in Kotlin release (see the 2026-11-22 QA note); if a Flutter upgrade breaks the build first, drop the 12-hour background job – reminders then run about 3 days past the last app open
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
- Public Play Store release: a new personal developer account first needs a closed test with at least 12 testers for 14 days, plus the store listing, Data safety form and privacy policy
