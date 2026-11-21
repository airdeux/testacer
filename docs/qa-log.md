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
| 2026-11-21 | – | CI (GitHub Actions) | push fe19dde (Firebase config) | Fail → fixed | `flutter analyze`: `lib/firebase_options.dart` imports `firebase_core`, which was not a dependency; fix `flutter pub add firebase_core` (checked: analyze clean, 17/17 tests). Also `actions/checkout` v4 → v5 (Node 20 deprecation warning) |
