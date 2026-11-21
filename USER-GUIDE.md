# Test Acer – User guide

> **Draft.** This outline describes the planned behaviour. It is completed, with screenshots, in Phase 8 (see [docs/plan-and-tasks.md](docs/plan-and-tasks.md)). The final guide will be in Hungarian.

## 1. Getting access

- **Web:** open https://airdeux.github.io/testacer/ in any browser (on a phone you can add it to the home screen). **Android:** install the app from the link the admin sends.
- Ask the admin for an invitation (they need your email address).
- Sign in with **Google**, with **email + password**, or with an **email link**: type your email address and open the link you receive – on the same phone or browser where you asked for it.
- With a password account, open the verification email once before the first sign-in.
- If you see "not invited yet", the admin has not added your email address.

## 2. Choosing a question set

- The start page shows the question set you practise (the first one is the judo 2nd dan practice test, 149 questions). If there are several, pick one from the **Kérdéssor** list; the app remembers it on all your devices.

## 3. Practising

- Choose how many questions (**Kérdések száma**): 1, 5, 10, **Mind** (every question once), or **∞** (until you close the quiz). Then tap **Gyakorlás indítása**.
- Each question shows its four answers (A–D) in a random order. Tap the one you think is correct.
- The result follows: green = correct, red = your wrong choice. Below it, the correct answer is shown with its ***subject*** and the **words that make it different** from the wrong answers highlighted, plus a note where there is one.
- **Bébikönnyű – ne kérdezd többet:** switch it on for a question you already know well; it will not be asked again (undo it on the Haladás page).
- **Következő** goes on; after the last question (or when you close the quiz with ✕) you see your score and can start a new round.
- Questions you answer wrong come back more often; questions you keep answering right come up less and less.

## 4. Progress (Haladás)

- How many questions you have seen, your overall accuracy, how many questions are in each stage (new / wrong → "jól megy"), the questions you get wrong most often, and the list of "known" questions with **Visszavétel** (undo).

## 5. Reminders (Android app)

- Install the app from the link the admin sends (Firebase App Distribution or an APK file).
- Allow notifications when the app asks.
- In **Settings → Reminders**, add one or more time windows, e.g. every day 09:00–22:00, every 60 minutes. Use "send a test notification" to check.
- Tapping a reminder opens a short quiz that starts with the question from the notification.
- If reminders arrive late or not at all: exclude Test Acer from battery optimisation (Android settings → Apps → Test Acer → Battery → Unrestricted). Exact names differ by phone brand.

## 6. Answering in the notification (optional)

- In **Settings → Reminders**, choose "answer in the notification".
- The notification shows one statement. Tap **Igaz** (true) or **Hamis** (false) – the app does not open.
- The notification then shows the result and the next statement. Dismiss it to stop.
- **Összes válasz** opens the app with the same question and all 4 answer options; pick one, see the result, then **Bezár** or **Következő** (continues as a short quiz). The skippable switch is here too.
- Answers given this way are saved on the phone and synced the next time you open the app.

## 7. Web version

- Open the web address the admin sends, from any browser. Your progress and settings are the same as in the Android app.
- Reminders are not available on the web.

## 8. Troubleshooting

| Problem | What to try |
|---|---|
| Google sign-in fails | make sure the email of that Google account is the one you were invited with |
| No reminders | check notification permission, battery optimisation, and that a reminder window covers the current time |
| Progress missing on the other device | open the Android app once while online so it can sync |
| Sign-in link does not arrive | check the spam folder; the sender is a `firebaseapp.com` address |
| Sign-in link asks for the email again | it was opened on another device or browser; enter the same address, or request a new link on this device |

## 9. For the admin

- **Import a question set:** the ⬆ (Kérdéssor importálása) button on the start page → **Fájl kiválasztása (.md)** → a Markdown file in the [question format](docs/question-format.md) → check the report and the preview → choose **Új kérdéssor** or an existing set to update → **Importálás**. Updating keeps everyone's progress for unchanged questions; questions no longer in the file are removed.
- **Invite a user:** Admin → Users → add email address.
