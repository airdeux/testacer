/// Public address of the web app (GitHub Pages).
///
/// Used as the "continue URL" of sign-in links sent from the Android app.
/// The domain must be listed under Firebase Authentication → Settings →
/// Authorized domains.
const webAppUrl = 'https://airdeux.github.io/TestAcer/';

/// Android application ID; sign-in links open the app with this package.
const androidPackageName = 'com.airdeux.testacer';

/// Firebase Hosting domain that e-mail sign-in links go through
/// (Dynamic Links shut down in 2025). It serves
/// `/.well-known/assetlinks.json` from firebase/hosting, so the links open
/// the Android app.
const authLinkDomain = 'testacer-892b3.firebaseapp.com';
