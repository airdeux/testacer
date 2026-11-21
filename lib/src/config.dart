/// Public address of the web app (GitHub Pages).
///
/// Used as the "continue URL" of sign-in links sent from the Android app.
/// The domain must be listed under Firebase Authentication → Settings →
/// Authorized domains.
const webAppUrl = 'https://airdeux.github.io/testacer/';

/// Android application ID; sign-in links open the app with this package.
const androidPackageName = 'com.airdeux.testacer';

// E-mail sign-in links go through the project's default Firebase Hosting
// domain, testacer-892b3.firebaseapp.com (Dynamic Links shut down in 2025).
// Firebase picks it by itself; it must not be passed as `linkDomain`.
// The domain serves `/.well-known/assetlinks.json` from firebase/hosting, so
// the links open the Android app (see the intent filter in
// AndroidManifest.xml).
