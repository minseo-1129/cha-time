# Tea — Android release checklist

## Release identity

- App name: `Tea`
- Application ID: `com.teawithyou.app`
- Version: `1.0.0+1`
- App data remains local on-device.

> The application ID is now fixed for Play release. Do not change `com.teawithyou.app` after the first Play Console upload.

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

Choose a password you can store safely. The keystore is needed for future uploads, so back it up somewhere secure.

## 2. Create android/key.properties

Copy the example:

```bash
cp android/key.properties.example android/key.properties
```

Then edit `android/key.properties`:

```properties
storePassword=YOUR_STORE_PASSWORD
keyPassword=YOUR_KEY_PASSWORD
keyAlias=upload
storeFile=../upload-keystore.jks
```

Both `android/key.properties` and `*.jks` are ignored by Git.

## 3. Build the release bundle

Once the two private signing files exist:

```bash
bash scripts/build_release.sh
```

The script runs:

- `flutter clean`
- `flutter pub get`
- `flutter analyze`
- `flutter build appbundle --release`

Expected output:

```text
build/app/outputs/bundle/release/app-release.aab
```

## 4. Install/test locally before Play upload

For normal device QA, continue using:

```bash
flutter run -d R3CWC0JDAER
```

The release bundle itself is for Play Console upload.

## 5. Closed testing

Follow `PLAY_CONSOLE_CLOSED_TESTING.md`.

Before every later Play build, increment the build number in `pubspec.yaml`, for example:

```yaml
version: 1.0.0+2
```

## Security

Never commit or send:

- `android/upload-keystore.jks`
- `android/key.properties`
- any keystore password
