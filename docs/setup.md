# Setup – owner's steps (Phases 0–5)

These steps need your computer, your GitHub account or your Google account. Run the commands in **PowerShell** in `C:\Work\misc\judo\TestAcer`, in this order.

Already prepared in the folder: docs, `.gitignore`, `firebase.json`, `firebase/firestore.rules`, the CI workflow, the question parser (`lib/src/question_format/`), its tests, the validator (`tool/`), and a local copy of the question file in the git-ignored `data/` folder.

## 1. Flutter project

```powershell
flutter --version          # stable channel
flutter create --platforms=web,android --org hu.example --project-name testacer .
flutter pub add crypto
flutter test
dart run tool/validate_questions.dart data/gyakorlo_teszt_osszes_valasz.md
```

- Replace `hu.example` with your own reverse domain: the Android app ID becomes `<org>.testacer` and cannot be changed once testers have installed the app.
- `flutter create .` adds `pubspec.yaml`, `analysis_options.yaml`, `lib/main.dart`, `android/`, `web/` and a sample widget test. It does not overwrite existing files.
- Expected (already checked by Claude with Flutter 3.50.1): `flutter analyze` – no issues; `flutter test` – 17 tests pass (the real-file test runs because `data/` contains the question file); the validator prints `Questions: 149`, `Options: 149 × 4`, `OK (0 warning(s))`.
- Also run `flutter analyze` – CI fails on any finding, including infos.

If something fails, paste the output to Claude.

## 2. GitHub repository

1. On github.com create a **public** repository named `TestAcer`, without README, license or .gitignore.
2. Then:

```powershell
git init -b main
git add .
git status                 # data/ must NOT be listed
git commit -m "Initial setup: docs, Flutter project, question parser"
git remote add origin https://github.com/<your-user>/testacer.git
git push -u origin main
```

3. Open the repository's **Actions** tab: the **CI** run should be green.

GitHub Pages is switched on later, in Phase 4.

## 3. Firebase project

In the console (https://console.firebase.google.com):

1. **Add project** – name `testacer`; Google Analytics is not needed. Stay on the **Spark** (no-cost) plan.
2. **Build → Authentication → Get started → Sign-in method:** enable **Email/Password** with **Email link (passwordless sign-in)** switched on (D-013), and **Google** (choose your e-mail as the support address).
3. **Build → Firestore Database → Create database:** production mode, an **EU location** (e.g. `eur3` or `europe-west1`). The location cannot be changed later.
4. **Firestore → Data:** start collection `allowlist`, document ID = your e-mail address **in lower case**, fields `role` (string) = `admin`, `invitedAt` (timestamp) = now. This makes you the first admin.

Then on your PC (Node.js is needed for the Firebase CLI):

```powershell
npm install -g firebase-tools
firebase login
dart pub global activate flutterfire_cli
flutterfire configure --project=<your-project-id> --platforms=android,web
flutter pub add firebase_core           # firebase_options.dart imports it; without it `flutter analyze` fails
firebase use --add                      # choose the project, alias: default
firebase deploy --only firestore:rules,firestore:indexes
```

- `flutterfire configure` creates `lib/firebase_options.dart` and `android/app/google-services.json`. Commit both: they identify the project but are not secrets (access is protected by the security rules).
- `firebase use --add` creates `.firebaserc`; commit it too.

## 4. Android fingerprints (for Google sign-in)

```powershell
keytool -list -v -keystore "$env:USERPROFILE\.android\debug.keystore" -alias androiddebugkey -storepass android -keypass android
```

(`keytool` ships with the JDK in Android Studio, e.g. `C:\Program Files\Android\Android Studio\jbr\bin\keytool.exe`.)

Copy the **SHA1** and **SHA256** values to Firebase console → Project settings → Your apps → the Android app → **Add fingerprint**. The release key's fingerprints are added in § 7.2.

## 5. Sign-in setup (Phase 2)

1. **Authorised domain:** Firebase console → Authentication → **Settings → Authorized domains → Add domain**: `airdeux.github.io`. Sign-in links sent from the Android app lead back to the web app there (and Google sign-in on the published web app needs it).
2. **Packages:** `flutter pub get`.
3. **Sign-in links open the app:** the debug key's SHA-256 goes into `firebase/hosting/.well-known/assetlinks.json` (Claude prepares it from the `SHA256:` line of the `keytool` command in § 4). Then:

   ```powershell
   firebase deploy --only hosting
   ```

   Check: https://testacer-892b3.firebaseapp.com/.well-known/assetlinks.json shows the file.
4. **E-mail texts:** Firebase console → ⚙ **Project settings → General → Public-facing name**: `Kvíz-maxoló` (it replaces „project-386828959446” in the sign-in e-mails). Optionally **Authentication → Templates**: for each template, ✏ → **Sender name**: `Kvíz-maxoló`. The app asks Firebase for Hungarian e-mails (`setLanguageCode('hu')` in `lib/main.dart`).
5. **Try it:** `flutter run -d chrome` and `flutter run -d <android-device>`; sign in all three ways (see the QA log's release checklist).

## 6. Web deploy to GitHub Pages (Phase 4)

1. **Workflow file:** create `.github/workflows/deploy-web.yml` with the content Claude provides (Claude cannot write into `.github/workflows/`).
2. **Turn on Pages:** GitHub → the repository → **Settings → Pages → Build and deployment → Source: GitHub Actions**.
3. **Push to `main`.** The *CI* workflow runs first; when it passes, *Deploy web* builds the app and publishes it. To publish without a new commit: **Actions → Deploy web → Run workflow**.
4. **Check:** https://airdeux.github.io/testacer/ shows the sign-in screen; the *Deploy web* run shows the address under *deploy*.

Lower-case address (one-off, 2026-11-21): the Pages path is the repository name, case-sensitively. To move from `/TestAcer/` to `/testacer/`:

1. GitHub → the repository → **Settings → General → Repository name**: `testacer` → **Rename**. GitHub redirects the old repository and clone addresses, but the old Pages address stops working.
2. Point your clone at the new name: `git remote set-url origin https://airdeux@github.com/airdeux/testacer.git`
3. Apply the two `TestAcer` → `testacer` changes in `.github/workflows/deploy-web.yml` (comment and `--base-href`), then commit and push; *Deploy web* publishes to the new address.
4. `firebase deploy --only hosting` (the redirect page on testacer-892b3.web.app now points to the new address).

How it works:

- *Deploy web* starts when *CI* finishes on a push to `main`, and only builds if CI passed; it builds the exact commit CI tested (`flutter build web --release --base-href /testacer/`).
- Pushes to other branches and pull requests are tested by CI but not published.
- GitHub Pages caches files for about 10 minutes; after a deploy, reload the page (Ctrl+F5) if the old version still shows.
- The Firebase web config in `lib/firebase_options.dart` is public by design; access is protected by the sign-in, the allowlist and the Firestore rules.

## 7. Android reminders and release build (Phase 5)

### 7.1 Try the reminders on your phone (debug build)

1. `flutter pub get`, then `flutter run -d <android-device>`.
   - The notification plugin needs **Android SDK platform 37**. If Gradle stops with "Failed to find target … android-37", install it in Android Studio → **Settings → Languages & Frameworks → Android SDK → SDK Platforms → Android 17 (API 37)**, then run again.
2. In the app: **Emlékeztetők** → switch on → allow notifications → **Mentés**. **Próbaértesítés küldése** shows one at once; tapping it opens a quiz with that question.
3. To see a scheduled one soon, add a window with today's next few minutes as *Első* and *Utolsó* (e.g. 21:40–21:55, every 15 minutes).

### 7.2 Release signing key (once)

Create the key **outside the repository** and keep a backup – updates must be signed with the same key:

```powershell
mkdir "$env:USERPROFILE\keys"
keytool -genkeypair -v -keystore "$env:USERPROFILE\keys\testacer-upload.jks" -storetype JKS -keyalg RSA -keysize 2048 -validity 10000 -alias upload
```

`keytool` asks for a password and your name; remember the password. Then create `android/key.properties` (git-ignored, never commit it):

```properties
storePassword=<the password>
keyPassword=<the password>
keyAlias=upload
storeFile=C:/Users/<you>/keys/testacer-upload.jks
```

Without this file, release builds are signed with the debug key (fine for trying, not for distribution).

**Fingerprints** – show them with:

```powershell
keytool -list -v -keystore "$env:USERPROFILE\keys\testacer-upload.jks" -alias upload
```

1. Copy **SHA1** and **SHA256** to Firebase console → Project settings → Your apps → the Android app → **Add fingerprint** (Google sign-in in the release app needs them), then run `flutterfire configure` again (as in § 3) to refresh `google-services.json`.
2. Send Claude the **SHA256** line: it goes into `firebase/hosting/.well-known/assetlinks.json` next to the debug key, so sign-in links open the release app too. Then `firebase deploy --only hosting`.

### 7.3 Build and distribute

1. Raise the version in `pubspec.yaml` for every release, e.g. `version: 1.0.0+1` → `1.0.1+2` (the number after `+` must grow).
2. Build: `flutter build apk --release` → `build\app\outputs\flutter-apk\app-release.apk`.
3. First time only: Firebase console → **App Distribution** → choose the Android app → **Get started**.
4. Upload and invite testers:

   ```powershell
   firebase appdistribution:distribute build\app\outputs\flutter-apk\app-release.apk --app 1:386828959446:android:8cbac790d88f4bc9755377 --testers "elso@example.com,masodik@example.com" --release-notes "Emlékeztetők"
   ```

   Testers get an e-mail; they install the app through the **App Tester** app or the download page, and allow installing from that source when Android asks. Their e-mail addresses must also be invited in the app itself (allowlist).

## Firestore rules tests (optional, also run by CI)

```powershell
cd firebase
npm ci
npm test        # starts the Firestore emulator (needs Java 21+) and runs firebase/test
```
