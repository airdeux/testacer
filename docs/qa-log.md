# QA log – TestAcer

## Test strategy

| Level | What | Tool |
|---|---|---|
| Unit | parser, question key, selection engine, reminder planner, notification answer handler, sync merge | `flutter test` |
| Rules | Firestore security rules | Firebase emulator + rules tests |
| Widget | quiz, feedback, settings, sign-in screens | `flutter test` (widget tests) |
| Manual | sign-in, web deploy, reminders and background answering on real Android devices, offline + sync | release checklist below |

## Release checklist (run before every release)

- [ ] Sign-in on web and Android: email + password (new account, existing, password reset), email link (same device; another device asks for the address), and Google
- [ ] Email link on Android opens the app (not the browser) – needs the Hosting `assetlinks.json`
- [ ] A password account sees "verify your e-mail" until verified; after "Megerősítettem" it gets in
- [ ] Admin: inviting a waiting user lets them in without reload; revoking needs confirmation; own address cannot be revoked
- [ ] A non-invited account sees "not invited yet" and cannot read any data
- [ ] Import of the real question file: 149 questions, no errors
- [ ] Quiz: options shuffled, no emphasis before answering, emphasis and note in feedback
- [ ] A skippable question never appears; undo brings it back
- [ ] A question answered wrong comes back noticeably more often (sample of 50 picks)
- [ ] Reminders arrive inside the window and never outside it; they survive a reboot and a daylight-saving change
- [ ] Notification answering works with the app closed; result + next statement; answers synced after the next app start
- [ ] Offline quiz on Android, sync after reconnecting
- [ ] Web on GitHub Pages: reload on a deep link (`#/quiz`) works

## Log

| Date | Version | Area | Check | Result | Notes |
|---|---|---|---|---|---|
| 2026-11-21 | – | Source data | `gyakorlo_teszt_osszes_valasz.md` against the judo.maze.hu review of attempt 8986 | Pass | 149 questions × 4 options, 1 correct each; the collected text matched the site byte for byte (SHA-256) before the subject emphasis was added. #15 (Itsutsu-no-Kata): the site accepts 2 answers; only "az öt alapelv" is kept as correct, by the owner's decision |
| 2026-11-21 | – | Question format | Format rules checked on the real file with a Python mirror of the parser | Pass | 149 questions, 4 options each, exactly one ✔, 149 unique keys, no unparsed lines or emphasis problems; #3 subject „Yoshi”, differs „fojtasd.”; #15 note found |
| 2026-11-21 | – | Parser (Dart) | `flutter analyze`, `flutter test`, validator on the real file – on a temporary copy after `flutter create` (Flutter 3.50.1, Dart 3.14.0, Linux) | Pass | analyze: no issues; 17/17 tests (16 parser + the template widget test) after fixing one test fixture (2 options → 4); validator: 149 questions, 149 × 4 options, 0 warnings |
| 2026-11-21 | – | Project setup (owner, Windows) | `flutter create`, `flutter test`, validator – Flutter 3.50.1 | Pass | 17/17 tests; validator 149 × 4, 0 warnings |
| 2026-11-21 | – | CI (GitHub Actions) | first push: `flutter analyze`, `flutter test` | Pass | run 44921409780; `data/` confirmed absent from the repository |
| 2026-11-21 | – | Phase 2 (sign-in) | `flutter analyze`, `flutter test`, `flutter build web`, rules tests – Flutter 3.50.1, firebase-tools 15.37.0, Java 21 (Claude's workspace) | Pass | analyze clean; 44/44 Flutter tests (models, e-mail link controller, sign-in, invitations, app gate, parser); web release build OK; 12/12 Firestore rules tests against the emulator. Not yet tested on a device: real Google / password / e-mail-link sign-in |
| 2026-11-21 | – | Phase 3 (quiz) | `flutter analyze`, `flutter test`, `flutter build web`, rules tests – Flutter 3.50.1 (Claude's workspace) | Pass | analyze clean; 77/77 Flutter tests (new: selection, progress records, quiz session, codec incl. all 149 real questions, home, quiz, progress and import screens); web build OK; 12/12 rules tests. Not yet tried with the live project |
| 2026-11-21 | – | Phase 2 – manual (owner) | sign-in on the live project; `flutter analyze`, `flutter test` on Windows | Pass | admin home screen reached ("Szia, Gábor Erdei!", role Adminisztrátor); Hosting `assetlinks.json` served |
| 2026-11-21 | – | Phase 3 – manual (owner) | live project: import of the real question file; 10-question quiz on web (Chrome) and Android (Samsung SM-S928B); progress page | Pass | quiz works on both; progress persists; statistics correct |
| 2026-11-21 | – | Phase 4 – web deploy | *Deploy web* #1 after CI on `main`; https://airdeux.github.io/TestAcer/ opened in the desktop app's built-in browser (Chromium) | Pass | sign-in screen renders; app files, CanvasKit and Firebase SDK load (200); only error: 404 for the browser's automatic `/favicon.ico` at the domain root (harmless). Sign-in on the live site and other browsers: owner |
| 2026-11-21 | – | Phase 4 – lower-case address | repository renamed to `testacer`; *Deploy web* re-run; https://airdeux.github.io/testacer/ and the Hosting redirect page checked in the built-in browser | Pass | sign-in screen renders, all app files 200 from `/testacer/`, no failed requests; old `/TestAcer/` gives 404 (expected); testacer-892b3.firebaseapp.com redirects to the new address. Note: a deploy pushed before the rename was published to the old path with the new base path and failed to load – rename first, then push |
| 2026-11-21 | – | Phase 4 – e-mail link on the live site | owner: „Belépési link küldése e-mailben” on https://airdeux.github.io/testacer/ | Fail → fixed | „Váratlan hiba történt”; reproduced by Claude with `test@example.com`: Firebase answered 400 `INVALID_HOSTING_LINK_DOMAIN` (the default `firebaseapp.com` domain may not be set as `linkDomain`); without it the request succeeds (200). Fix: `linkDomain` removed; unexpected errors now show the error code. Owner to retest after the deploy |
| 2026-11-21 | – | Phase 5 (reminders) | `flutter analyze`, `flutter test`, `flutter build web` – Flutter 3.50.1 (Claude's workspace, no Android SDK) | Pass | analyze clean; 117/117 tests (new: reminder settings, planner incl. the spring and autumn daylight-saving changes and overlapping windows, question assignment, reminder service with fakes incl. background re-plan and taps, settings screen incl. a 320 px wide phone, home page sync and tapped reminders, quiz starting question); web build OK (+186 KB, time-zone data). Not yet built for Android or tried on a device |
| 2026-11-22 | – | Phase 6 (answering in the notification) | `flutter analyze`, `flutter test`, `flutter build web` (Claude's workspace) | Pass | analyze clean; 128/128 tests (new: true/false plan with statements about half true, right and wrong answers with result + next statement + progress + re-plan, background answer queued then synced on the next app start, replay keeping a later `lastAt`, other users' answers kept, queue JSON, button/tap routing, mode switch on the settings screen); web build OK. Not yet tried on a device |
| 2026-11-22 | – | Phase 5 – release build | owner: `flutter build apk --release` with the release key; `firebase appdistribution:distribute` to the owner | Pass (with a warning) | APK 54 MB, version 1.0.0 (1); distributed. Warning: `workmanager_android` 0.10.9 (latest) still applies the Kotlin Gradle Plugin, which future Flutter versions will refuse – no newer version yet; tracked in Phase 7 |
| 2026-11-21 | – | CI (GitHub Actions) | push fe19dde (Firebase config) | Fail → fixed | `flutter analyze`: `lib/firebase_options.dart` imports `firebase_core`, which was not a dependency; fix `flutter pub add firebase_core` (checked: analyze clean, 17/17 tests). Also `actions/checkout` v4 → v5 (Node 20 deprecation warning) |
