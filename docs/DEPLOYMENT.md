# Shmuki Talk — Deployment Guide

## Prerequisites

1. Flutter 3.24+ installed
2. Firebase project created
3. Google Play Developer account
4. Apple Developer account (for iOS)
5. Xcode 15+ (for iOS builds)

---

## 1. Firebase Setup

### 1.1 Create Firebase Project
1. Go to https://console.firebase.google.com
2. Create new project: `shmuki-talk`
3. Enable Google Analytics (optional)

### 1.2 Enable Firebase Services
Enable the following in Firebase console:
- **Authentication** → Google Sign-In provider
- **Firestore** → Create database (production mode)
- **Storage** → Enable
- **Cloud Messaging** → Enable
- **Hosting** → Enable

### 1.3 Run FlutterFire CLI
```bash
dart pub global activate flutterfire_cli
flutterfire configure --project=shmuki-talk
```
This generates `lib/core/config/firebase_options.dart`

### 1.4 Deploy Firestore Security Rules
```bash
firebase deploy --only firestore:rules
firebase deploy --only firestore:indexes
```
Rules are in `docs/SECURITY_RULES.md`

### 1.5 Deploy Storage Rules
```
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    match /room_images/{roomId}/{file} {
      allow read: if request.auth != null;
      allow write: if request.auth != null
                   && resource == null || request.resource.size < 5 * 1024 * 1024;
    }
    match /user_avatars/{userId}/{file} {
      allow read: if request.auth != null;
      allow write: if request.auth.uid == userId;
    }
  }
}
```

---

## 2. Android Setup

### 2.1 Google Play Setup
1. Create app at https://play.google.com/console
2. Package name: `com.shmuki.talk`
3. Add `android/app/google-services.json` from Firebase console

### 2.2 Generate Signing Key
```bash
keytool -genkey -v \
  -keystore android/app/upload-keystore.jks \
  -keyalg RSA \
  -keysize 2048 \
  -validity 10000 \
  -alias upload
```

### 2.3 Configure key.properties
Create `android/key.properties`:
```
storePassword=YOUR_STORE_PASSWORD
keyPassword=YOUR_KEY_PASSWORD
keyAlias=upload
storeFile=upload-keystore.jks
```

### 2.4 Build Release AAB
```bash
flutter build appbundle --release
```

### 2.5 Upload to Play Console
1. Go to Production → Releases
2. Upload `build/app/outputs/bundle/release/app-release.aab`
3. Complete store listing (screenshots, description in Hebrew)

---

## 3. iOS Setup

### 3.1 App Store Connect
1. Create app at https://appstoreconnect.apple.com
2. Bundle ID: `com.shmuki.talk`
3. Add `ios/Runner/GoogleService-Info.plist` from Firebase console

### 3.2 Signing
1. Open `ios/Runner.xcworkspace` in Xcode
2. Set Team and Signing Certificate
3. Create App Store Distribution certificate

### 3.3 Build IPA
```bash
flutter build ipa --release
```

### 3.4 Upload to TestFlight
```bash
xcrun altool --upload-app \
  --type ios \
  --file build/ios/ipa/shmuki_talk.ipa \
  --username YOUR_APPLE_ID \
  --password YOUR_APP_SPECIFIC_PASSWORD
```

---

## 4. Web Deployment

### 4.1 Build Web
```bash
flutter build web --release --pwa-strategy offline-first
```

### 4.2 Deploy to Firebase Hosting
```bash
firebase deploy --only hosting
```

### 4.3 Custom Domain (Optional)
1. Firebase Hosting → Add custom domain
2. Add `shmukitalk.app` (or your domain)
3. Update DNS records as instructed

---

## 5. GitHub Actions CI/CD

### Required Secrets
Set these in GitHub → Settings → Secrets:

| Secret | Description |
|--------|-------------|
| `FIREBASE_OPTIONS` | Content of firebase_options.dart |
| `FIREBASE_SERVICE_ACCOUNT` | Firebase service account JSON |
| `FIREBASE_PROJECT_ID` | Firebase project ID |
| `GOOGLE_SERVICES_JSON` | Android google-services.json |
| `IOS_GOOGLE_SERVICE_INFO` | iOS GoogleService-Info.plist |
| `ANDROID_KEYSTORE` | Base64-encoded keystore |
| `ANDROID_KEYSTORE_PASSWORD` | Keystore password |
| `ANDROID_KEY_PASSWORD` | Key password |
| `ANDROID_KEY_ALIAS` | Key alias |
| `PLAY_STORE_SERVICE_ACCOUNT` | Play Store service account JSON |
| `IOS_DISTRIBUTION_CERTIFICATE` | Base64-encoded P12 cert |
| `IOS_CERTIFICATE_PASSWORD` | Certificate password |
| `IOS_PROVISIONING_PROFILE` | Base64-encoded profile |
| `APP_STORE_CONNECT_KEY_ID` | App Store Connect API key ID |
| `APP_STORE_CONNECT_ISSUER_ID` | App Store Connect issuer ID |
| `APP_STORE_CONNECT_KEY` | Base64-encoded App Store Connect key |

### Release Process
1. Merge to `main` → triggers CI + deploy to Firebase Hosting
2. Create tag `v1.0.0` → triggers release pipeline to Play Store + App Store

---

## 6. Post-Deployment Checklist

- [ ] Test Google Sign-In on all platforms
- [ ] Create a test room and verify invite code sharing
- [ ] Test PTT in a room with 2+ users
- [ ] Test queue system with 3+ users
- [ ] Test notifications on all platforms
- [ ] Verify Firestore security rules block unauthenticated access
- [ ] Test deep link join flow
- [ ] Verify WhatsApp share works
- [ ] Test listener-only mode
- [ ] Test room locking/unlocking
- [ ] Load test with 20+ users
- [ ] Verify no audio is stored in Firebase Storage
