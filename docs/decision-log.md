# Decision log – TestAcer

Status: **Proposed** (waiting for the owner's OK) · **Accepted** · **Rejected** · **Superseded by D-xxx**.
Change a status by editing the table and the entry; never delete an entry.
All decisions D-001 – D-013 were accepted by the owner on 2026-11-21.

| ID | Date | Decision | Status |
|---|---|---|---|
| D-001 | 2026-11-21 | Flutter, one codebase; native Android build, no WebView wrapper | Accepted |
| D-002 | 2026-11-21 | Web hosting on GitHub Pages (public repo); Firebase Hosting as fallback | Accepted |
| D-003 | 2026-11-21 | Firebase Auth + Cloud Firestore on the Spark plan; no Cloud Functions | Accepted |
| D-004 | 2026-11-21 | Reminders are on-device scheduled notifications, not FCM push | Accepted |
| D-005 | 2026-11-21 | Notification answering: true/false statement + „Összes válasz” button | Accepted |
| D-006 | 2026-11-21 | Question selection: Leitner boxes with weighted random choice | Accepted |
| D-007 | 2026-11-21 | Options shuffled; emphasis shown only in feedback | Accepted |
| D-008 | 2026-11-21 | Question content lives only in Firestore, not in the repository | Accepted |
| D-009 | 2026-11-21 | Email is the login name; invite-only allowlist | Accepted |
| D-010 | 2026-11-21 | Hungarian UI and user guide, prepared for translation | Accepted |
| D-011 | 2026-11-21 | Android distribution via Firebase App Distribution or direct APK | Superseded by D-014 |
| D-012 | 2026-11-21 | No iOS app in v1 | Accepted |
| D-013 | 2026-11-21 | Email link (passwordless) as a third sign-in method | Accepted |
| D-014 | 2026-11-22 | Testers get the Android app from Google Play internal testing | Accepted |
| D-015 | 2026-11-23 | At least half of every multi-question quiz is new (least-seen) questions | Accepted |
| D-016 | 2026-11-23 | Trivia items in the question file pop up after matching answers | Accepted |
| D-017 | 2026-11-23 | Progress follows a question whose correct answer was edited at the same number | Accepted |
| D-018 | 2026-11-25 | Quiz length 25 instead of „Mind”; a timer for every quiz | Accepted |

---

### D-001 – Flutter, native Android build

- **Context:** web and Android are needed; the Android app needs scheduled notifications with action buttons and background handling. The owner knows Flutter and React.
- **Decision:** one Flutter app compiled for web and Android. The Android app runs the same UI natively, so no WebView is needed.
- **Alternatives:** (a) React/Vite web app (PWA) + Capacitor shell with its Local Notifications plugin – good if a lighter web app matters more; (b) web app inside a WebView of a native shell – the notification code is native anyway, so this adds glue without saving work; (c) native Kotlin + separate web app – two UIs.
- **Consequences:** the Flutter web build loads more slowly than a typical React app on first visit (acceptable for <10 users); one set of tests; iOS stays possible later.

### D-002 – GitHub Pages for the web app

- **Context:** the owner would like GitHub Pages. On GitHub Free, Pages works only for **public** repositories; publishing Pages privately needs an organization on GitHub Enterprise Cloud.
- **Decision:** public repository, deployed to Pages by GitHub Actions. Question content is never in the repository (D-008).
- **Alternative:** Firebase Hosting – free usage quota, same Firebase project, works with a private repository, SPA rewrites and preview channels. Switch to it if the repository must stay private.
- **Owner, 2026-11-21:** a public repository is OK → Accepted.

### D-003 – Firebase Auth + Firestore, Spark plan

- **Context:** sign-in (email/password, Google), per-user settings and progress, <10 users, no budget.
- **Decision:** Firebase Authentication and Cloud Firestore on the no-cost Spark plan. No Cloud Functions, because they require the Blaze plan.
- **Consequences:** all logic runs in the app; access control is in Firestore security rules. Spark quotas (tens of thousands of document reads/writes per day) are far above the expected use; if a quota is exceeded, that product stops until the end of the month, so the progress-per-set single document (architecture) keeps reads low.

### D-004 – Local scheduled notifications for reminders

- **Context:** reminders follow a per-user schedule (e.g. hourly 09:00–22:00). Firebase Cloud Messaging is free, but someone must send the messages on time: Cloud Functions (Blaze plan) or an external cron.
- **Decision:** the Android app schedules its own notifications with `flutter_local_notifications` (rolling one-off schedule, see architecture). FCM is kept for later (web reminders, announcements).
- **Consequences:** works offline and costs nothing; the schedule is per device (re-planned from the synced settings on each device); no reminders on the web in the MVP. A scheduled notification's content is fixed when it is scheduled, so reminders use a rolling schedule of one-off notifications with pre-picked questions ([architecture § Reminders](architecture.md#reminders-android)).

### D-005 – True/false statement + „Összes válasz” in notifications

- **Context:** the owner wants to answer from the notification. Android notifications show at most 3 action buttons; the questions have 4 options.
- **Decision (owner, 2026-11-21):** the notification shows one statement – the correct option or a random wrong one – with three buttons:
  - **Igaz** / **Hamis** – answered in the background without opening the app; the notification then shows the result and the next statement.
  - **Összes válasz** – opens the app with a dialog showing the same question with all 4 options (shuffled, single-select), then the usual feedback.
- Every option in the question set is a full sentence, so each works as a standalone statement. The earlier idea of an „Ismert” (mark skippable) button is dropped because of the 3-button limit; the skippable toggle is in the dialog's feedback instead.
- **Alternatives considered:** inline text reply ("A–D") – clumsy; a custom notification layout with 4 buttons – needs native Android code and is fragile across devices.
- **Implementation note (2026-11-22):** the statement is the correct option half of the time, so „Igaz” and „Hamis” are equally often right. „Összes válasz” opens the existing quick-quiz page on that question instead of a separate dialog: it already has the shuffled single-select options, the feedback with the skippable toggle, „Következő” and ✕ (close); a dialog would have duplicated it.

### D-006 – Leitner boxes for question selection

- **Context:** questions answered wrong should come back more often; known ones less often; skippable ones never.
- **Decision:** each question has a box 0–4 (wrong → 0, correct → +1). Selection is weighted random with weights 8 / 4 / 2 / 1 / 0.5 by box; skippable questions and the last 5 asked are excluded. Simple to explain and to tune.
- **Alternatives:** SM-2 or FSRS spaced repetition – better for long-term memory, but they schedule by date, which suits "every hour" reminders less well. Can be revisited after the beta.

### D-007 – Shuffled options, emphasis only in feedback

- **Context:** in the source file the correct answer is always first and contains emphasis.
- **Decision:** options are shuffled for every question; emphasis is removed while answering and shown in the feedback view.

### D-008 – Question content only in Firestore

- **Context:** the questions come from a training site's practice test and should stay within the group; the repository will probably be public (D-002).
- **Decision:** question files are not committed (`data/` is git-ignored). The admin imports a file in the app; it is validated, previewed, then written to Firestore, readable only by invited users. A CLI validator (`tool/`) checks files locally.

### D-009 – Email as login name, invite-only

- **Context:** "user + password or Google account". Firebase email/password sign-in identifies users by email address.
- **Decision (owner OK, 2026-11-21):** the email address is the login name. Access requires an allowlist entry, added by the admin (only the owner for now). Password accounts must verify their email first.
- **Alternative:** real usernames mapped to synthetic addresses (`name@testacer.invalid`) – possible, but password reset by email would not work.

### D-010 – Hungarian UI

- **Decision (owner OK, 2026-11-21):** the UI and the user guide are Hungarian for now; UI texts live in ARB files (Flutter `gen-l10n`) so English can be added later.

### D-011 – Android distribution

- **Context:** fewer than 10 testers; Play Store publishing needs a developer account and review.
- **Decision:** Firebase App Distribution (no-cost) or a signed APK shared directly. Play Store later if the group grows.
- **Superseded (2026-11-22) by D-014.** App Distribution stays available for the owner's own quick checks.

### D-012 – No iOS app in v1

- **Decision (owner, 2026-11-21):** iOS is out of scope for the first version. Flutter keeps it possible later (an iOS build would need an Apple developer account and its own notification permission handling).

### D-013 – Email link sign-in as a third method

- **Context:** the owner enabled "Email link (passwordless sign-in)" in Firebase Authentication and wants it next to email + password and Google.
- **Decision (owner, 2026-11-21):** the sign-in screen offers Google, email + password, and email link. All three give the same kind of Firebase user, identified by e-mail; the allowlist check is the same.
- **Consequences:** a link sign-in also verifies the e-mail. On Android the link opens the app through the project's Firebase Hosting domain (`<project-id>.firebaseapp.com`, path `/__/auth/links`), which needs an App Links intent filter and the SHA fingerprints; Firebase Dynamic Links, used for this earlier, shut down in August 2025. The link should be opened on the device where sign-in started, otherwise the app asks for the e-mail again. The sign-in e-mails come from a `firebaseapp.com` address and can land in spam.
- **Implementation note (2026-11-21):** the Hosting domain had no site, so `assetlinks.json` could not be served. A minimal Firebase Hosting site (`firebase/hosting`, Spark plan) now serves it; its index page only redirects to the GitHub Pages app.
- **Implementation note (2026-11-21, fix):** `ActionCodeSettings.linkDomain` must not be set to the default Hosting domain – Firebase rejects it (`INVALID_HOSTING_LINK_DOMAIN`: "cannot be a default hosting domain"), so every link request failed. Without `linkDomain` Firebase uses `<project-id>.firebaseapp.com` anyway; `linkDomain` is only for a custom Hosting domain.

### D-014 – Google Play internal testing for testers

- **Context:** installing the App Distribution APK shows "this file type can be harmful" and a Google Play Protect block („Az alkalmazás le van tiltva…”, unknown developer). For testers who are classmates, not close friends, that looks untrustworthy.
- **Decision (owner, 2026-11-22):** testers install the app from Google Play through the **internal testing** track; the owner uses a personal Google Play developer account.
- **Consequences:** one-time USD 25 registration fee and identity verification. Internal testing has no review and no 12-tester / 14-day requirement (that only gates a public production release for new personal accounts), allows up to 100 testers by e-mail list, and can start before the store listing and Data safety form are complete. Builds are uploaded as app bundles (`.aab`) signed with the upload key; Play App Signing re-signs them with Google's app signing key, so that key's SHA-1 and SHA-256 must be added to Firebase (Google sign-in) and to `assetlinks.json` (sign-in links open the app) **before** testers install. A Play-installed app cannot be updated by an APK signed with the upload key and vice versa – uninstall one to install the other. Updates reach testers through the Play Store.

### D-015 – At least half of a quiz is new questions

- **Context:** with Leitner weights alone (D-006), questions answered wrong keep coming back and a user may take a long time to see all questions once. The owner wants every quiz to bring new material.
- **Decision (owner, 2026-11-23):** in a quiz of more than one question, at least half (rounded up: 3 of 5, 5 of 10) are questions not seen yet; if fewer are left, questions seen once fill the gap, then those seen twice, and so on.
- **Implementation:** every other question – the 1st, 3rd, 5th… – is picked by `QuestionPicker.pickFresh`: the fewest `seen` among the eligible questions (skippable never, no repeats in the quiz, the last 5 left out as usual), random among equals. The other questions are picked by Leitner weights as before; when those happen to be new too, the quiz simply has more new questions. Applies to 5, 10, 25 (*Mind* until D-018) and ∞ (every other question), and to the quiz a reminder opens (after its own question). Not to 1-question quizzes or to the reminders' own picks.
- **Consequences:** a quiz contains at least min(⌈n/2⌉, new questions left) new ones; once all are seen, the „fresh” half goes to the least-practised questions.

### D-016 – Trivia that pops up after matching answers

- **Context:** the owner added a `# Trivia` part to the question file: short „Tudtad?” items (dates, names, places) with keywords in square brackets, to be shown after an answer whose correct option mentions them.
- **Decision (owner, 2026-11-23):** after the user picks an answer – right or wrong – every trivia item with a keyword contained in the correct option pops up (bottom sheet, „Bezár” to close; the feedback stays underneath). Matching ignores case and extra spaces; keywords are plain text, so the file author chooses word stems where needed („olimpi”). Format in [question-format.md](question-format.md#trivia-d-016).
- **Implementation:** the parser reads the items after a level-1 heading that follows the questions; the import stores them in the set document (`trivia` list, a few KB); the quiz loads them once per quiz. Not shown in notifications.
- **Consequences:** an item matching many questions comes up often; that is up to the keywords. A „don't show again” option can be added if it gets repetitive.

### D-017 – Progress follows a question whose answer text was fixed

- **Context:** question keys come from the correct option's text (D-008 storage, [question-format.md](question-format.md#question-key)). Fixing a typo there gave the question a new key, so everyone's progress on it – including the „Bébikönnyű” mark – started again. The 2026-11-23 file fixes typos in 5 correct answers (questions 7, 18, 56, 107, 127).
- **Decision:** when updating a set, a question with a new key that has the same number as a question that disappears is the same question: it records the old key (and that question's earlier keys) as `previousKeys`. Wherever a user's progress is loaded, a question without a record under its key takes the record of its newest previous key; new answers are saved under the new key.
- **Alternatives considered:** keys from the question number (breaks when questions are reordered); rewriting every user's progress at import (needs admin access to other users' data, which the rules do not give).
- **Consequences:** typo fixes keep progress as long as the numbering stays; changing the numbering and the answer text in the same import does not carry progress over. The old record stays in the progress document unused (until „Haladás törlése”).

### D-018 – 25 questions instead of „Mind”; a quiz timer

- **Context:** „Mind” asked every question once – 149 for the judo set, too long for one sitting. The owner wants a longer standard round and to see how long a round takes.
- **Decision (owner, 2026-11-25):** the lengths are 1, 5, 10, **25** and ∞. A timer (`hh:mm:ss`) in the quiz's app bar starts with the first question and stops when the last question is answered; the result page shows the time. An ∞ quiz has no last question: its timer stops when the quiz is closed.
- **Implementation:** `QuizLength.twentyFive` replaces `all`; a stored `all` setting reads as 25. 25 follows D-015 (13 of 25 new where possible) and asks fewer when fewer questions are left. The timer measures wall-clock time (`QuizClock`, start/stop timestamps), so it stays right when the app or tab is in the background; it is not saved.
- **Consequences:** going through every question once is no longer one option; ∞ covers long sessions.
