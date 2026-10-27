# Nexo — Android APK Build & Installation Guide

You have **3 ways** to get Nexo running as a native Android app / APK:

---

## Option 1: Instant Android Install (WebAPK via Chrome — Zero Compile Time)
1. Open the hosted **Nexo** app URL in **Google Chrome on your Android phone**.
2. Tap the **"Install APK / App"** button at the top of the app (or tap the Chrome menu `⋮` → **Install app**).
3. Android Chrome automatically packages Nexo into a signed **WebAPK** with the flat Spark ring launcher icon, `#0F1115` splash screen, and full-screen standalone window.

---

## Option 2: Automated Cloud APK Build (GitHub Actions — No Android Studio Needed)
This ZIP already includes `.github/workflows/build-apk.yml`:
1. Create a new repository on GitHub and upload the contents of this ZIP.
2. Open the **Actions** tab in your GitHub repository.
3. The **Build Nexo Android APK** workflow will automatically run `flutter build apk --release` on Ubuntu + Java 17 and upload **`nexo-release-apk.zip`** containing `app-release.apk`!

---

## Option 3: Local Flutter CLI Build (`app-release.apk`)
If you have the Flutter SDK installed on your computer:

```bash
# 1. Generate the Android gradle wrapper if not present
flutter create --platforms=android --org app.nexo .
cp android_manifest_override.xml android/app/src/main/AndroidManifest.xml

# 2. Fetch packages
flutter pub get

# 3. Compile the release APK
flutter build apk --release
```

Your compiled APK will be ready at:
`build/app/outputs/flutter-apk/app-release.apk`
