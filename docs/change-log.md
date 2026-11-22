# Change log

All notable changes are listed here. Format: [Keep a Changelog](https://keepachangelog.com/en/1.1.0/); versions follow [Semantic Versioning](https://semver.org/).

## [Unreleased]

### Added

- 2026-11-22 – Release key's SHA-256 in `firebase/hosting/.well-known/assetlinks.json`, so sign-in links also open the release build.
- 2026-11-21 – Phase 5, Android reminders: **Emlékeztetők** screen (on/off, time windows with days, first/last time and interval, test notification, battery hint; synced per user); planner for the next 48 reminders in Europe/Budapest time with pre-picked questions (Leitner, no skippable, no repeats); re-planning on the home page, after quizzes, on settings changes and by a `workmanager` job every 12 hours from a snapshot on the phone; reboot handled by the plugin; tapping a reminder opens an endless quiz starting with its question; sign-out cancels reminders. Release signing via `android/key.properties`; Firebase App Distribution steps in `docs/setup.md` § 7. New packages: `flutter_local_notifications`, `timezone`, `workmanager`. 40 new tests (117 in all).
- 2026-11-21 – Phase 4, web deploy: workflow `.github/workflows/deploy-web.yml` publishes the web app to GitHub Pages (https://airdeux.github.io/TestAcer/) after CI passes on `main`; web shell with Hungarian language tag, description and theme colour; owner's steps in `docs/setup.md` § 6.
- 2026-11-21 – Phase 3, quiz: admin import of Markdown question files (validation, preview, new set or update); question-set picker and quiz length (1 / 5 / 10 / Mind / ∞) synced per user; quiz with shuffled options, Leitner-weighted question choice (D-006), feedback with emphasis and notes (D-007), "known – don't ask again" switch; progress page (boxes, accuracy, weakest questions, skippable list with undo); Firestore offline cache on the web; 33 new tests.
- 2026-11-21 – Phase 2, sign-in: Google, e-mail + password (with verification and password reset) and e-mail link sign-in; allowlist access gate with "not invited" and "verify e-mail" screens; admin invitations page; Hungarian texts (`lib/l10n/app_hu.arb`); Android App Links filter for sign-in links; minimal Firebase Hosting site for `assetlinks.json`; Firestore rules tests (`firebase/test`) and a CI job for them; 27 new Flutter tests.
- 2026-11-21 – Phase 0/1 files: `.gitignore`, `firebase.json`, Firestore rules and indexes, CI workflow, question-format parser (`lib/src/question_format/`) with unit tests, validator `tool/validate_questions.dart`, owner's setup guide `docs/setup.md`. Verified with Flutter 3.50.1: analyze clean, 17/17 tests pass.
- 2026-11-21 – Planning documents: README, project brief, architecture, plan and tasks, decision log, question format, QA log, change log, user guide draft.

### Fixed

- 2026-11-21 – E-mail link sign-in failed with „Váratlan hiba történt” on every platform: the request set `linkDomain` to the default Hosting domain, which Firebase rejects (`INVALID_HOSTING_LINK_DOMAIN`). `linkDomain` removed; Firebase uses that domain by default. Unexpected sign-in errors now show the Firebase error code, e.g. „Váratlan hiba történt (invalid-hosting-link-domain)”; 1 new test.

### Changed

- 2026-11-21 – Display name „Kvíz-maxoló” (also the Firebase public-facing name, used in the sign-in e-mails) instead of „Test Acer”: app bar, sign-in screen, browser tab, web manifest, Android launcher label, Hosting redirect page, user guide. Repository, web address, package and code names stay `testacer` / `TestAcer`.
- 2026-11-21 – Sign-in, verification and password e-mails are requested in Hungarian (`setLanguageCode('hu')`); owner sets the project's public-facing name so the e-mails no longer say „project-386828959446” (docs/setup.md § 5).
- 2026-11-21 – Web address in lower case: https://airdeux.github.io/testacer/ (repository renamed `TestAcer` → `testacer`; GitHub Pages paths are case-sensitive). Updated: deploy workflow base path, `webAppUrl` (sign-in link return address), Firebase Hosting redirect page, docs.
- 2026-11-21 – UI text: the app name is shown as „Test Acer” (app bar, sign-in screen, browser tab, web manifest, Android launcher label); the skippable switch and lists say „Bébikönnyű” instead of „Ismert”.
- 2026-11-21 – Owner's answers recorded: public repo + GitHub Pages, email as login name, single admin, Hungarian UI and user guide, notification buttons Igaz / Hamis / Összes válasz, no iOS in v1 (D-012 added; all decisions D-001 – D-012 accepted). Architecture: the rolling reminder schedule is explained in detail.
- 2026-11-21 – Email link (passwordless) added as a third sign-in method (D-013): decision log, architecture § Sign-in, brief, plan (Phase 2), README, setup, QA checklist, user guide.
