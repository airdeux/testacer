# Project brief – TestAcer

_Last updated: 2026-11-21_

## Background

The judo 2nd dan exam includes a theory test. The practice test on judo.maze.hu has 149 multiple-choice questions (4 options, 1 correct). All questions with all options have been collected into `gyakorlo_teszt_osszes_valasz.md`, with the correct answer first and its subject and distinguishing words emphasized. Practising on the website is slow: 149 pages per attempt, no focus on weak questions, no reminders.

## Goal

A small app that makes short, frequent practice easy: a few questions at a time, more often the ones you get wrong, with reminders on the phone during the day.

## Users

- **Owner / admin** – imports question sets, invites users (the only admin for now).
- **Learners** – fewer than 10 people at first (training partners preparing for the same exam), Hungarian-speaking.

## Scope – MVP

1. Sign-in with email + password, email link (passwordless) or Google; invite-only (D-009, D-013).
2. Import a question set from Markdown ([question-format.md](question-format.md)); re-importing keeps progress.
3. Quiz on web and Android: shuffled options, feedback after each answer with the emphasized correct answer, "skippable" toggle per question, quiz length setting (1, 5, 10, all, or endless until closed).
4. Question selection weighted towards questions answered wrong (Leitner boxes, D-006).
5. Progress view: overall accuracy, weak questions, skipped list with undo.
6. Android reminders in user-defined windows (days, start–end time, interval), e.g. every day 09:00–22:00 every 60 minutes. Tapping opens a short quiz.
7. Answer in the notification: a statement with **Igaz** / **Hamis**, plus **Összes válasz**, which opens the question with all 4 options in the app (D-005).
8. Settings and progress synced via Firestore; the Android app works offline and syncs later.

## Out of scope (for now)

iOS app (not in v1, D-012); reminders in the browser (web push); public sign-up; server-side push campaigns; other document formats (e.g. statement-only lists like `elmelet-kerdes-valaszok.md`); leaderboards; payments; Play Store release.

## Constraints

- Free tiers only: Firebase Spark plan (so no Cloud Functions), GitHub Free.
- The question content comes from a training site's practice test: keep it inside the invite-only app, not in a public repository or on a public web page.
- Time zone Europe/Budapest; UI and user guide in Hungarian (D-010).

## Success criteria

- All 149 questions import with 4 options and exactly 1 correct answer each.
- A learner can do a 5-question quiz on the phone in under a minute.
- Reminders arrive inside the configured windows (within the delay Android allows for inexact alarms) and never outside them.
- Progress made on the phone shows up on the web after sync, and vice versa.

## Main risks

| Risk | Mitigation |
|---|---|
| Android delays or drops scheduled notifications (Doze, battery optimisation, manufacturer restrictions) | inexact timing is fine for hourly reminders; the user guide explains battery settings; the schedule is refilled on every app start |
| A daily repeating notification would always show the same question | schedule one-off notifications with pre-picked questions and refill them ([architecture § Reminders](architecture.md#reminders-android)) |
| Answers given from a notification while the app is closed get lost | write them to a local queue first, sync on the next app start |
| Free GitHub Pages needs a public repository | keep question data out of the repo (Firestore only); fallback: Firebase Hosting with a private repo (D-002) |
