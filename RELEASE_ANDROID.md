# Tea — Android release checklist

## Release identity

- App name: `Tea`
- Application ID: `com.teawithyou.app`
- Version: read from `pubspec.yaml`
- App data remains local on-device.

> Changing the application ID makes Android treat this as a different app from the earlier `com.example.doodle` development build. Existing local test data from that development package does not migrate automatically.

## 1. Create the upload keystore once

From Git Bash in the project root:

```bash
keytool -genkeypair -v \
  -keystore android/upload-keystore.jks \
  -keyalg RSA \
  -keysize 2048 \
  -validity 10000 \
  -alias upload
```

Keep this keystore safe. Do not commit it.

## 2. Create android/key.properties

Copy `android/key.properties.example` to `android/key.properties` and replace the passwords:

```properties
storePassword=YOUR_STORE_PASSWORD
keyPassword=YOUR_KEY_PASSWORD
keyAlias=upload
storeFile=../upload-keystore.jks
```

Both `android/key.properties` and `*.jks` are already ignored by Git.

## 3. Verify locally

```bash
flutter clean
flutter pub get
flutter analyze
flutter run -d R3CWC0JDAER
```

Because the application ID changed, Android may install Tea as a new app alongside the old development build.

## 4. Build the Play bundle

```bash
flutter build appbundle --release
```

Expected output:

```text
build/app/outputs/bundle/release/app-release.aab
```

Before uploading a new Play build later, increment the build number in `pubspec.yaml`, e.g. `1.0.0+2`.

## 5. Closed testing

Upload `app-release.aab` to the Google Play Console closed-testing track, complete the required store/data-safety declarations, add testers, and publish the closed-test release.

The Play Store listing icon is a separate 512×512 asset from the launcher icon bundled in the Android app.
