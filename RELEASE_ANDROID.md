# Tea — Android release checklist

## Release identity

- App name: `Tea`
- Application ID: `com.teawithyou.app`
- Version: `1.0.0+3`
- App data remains local on-device.

> The application ID is fixed for Play release. Do not change `com.teawithyou.app`.

## Current release-candidate status

The launcher icon is confirmed visible on the Samsung test device.

The last release build before commit `f1cc9c4` failed during `:app:mergeReleaseResources` because obsolete corrupted PNG files still existed under Android `res/`.

Commit `f1cc9c4` removed those obsolete resources. A fresh post-cleanup release build still needs to be confirmed.

Run:

```bash
cd /c/dev/cha-time
git pull origin main
bash scripts/build_release.sh
```

Only treat the bundle as release-ready after that command succeeds.

## 1. Upload keystore

Tea uses the same local key layout as the other Android projects. Keep the upload key outside the Git repository:

```text
C:\dev\keys\tea-upload-key.jks
```

Git Bash path:

```text
C:/dev/keys/tea-upload-key.jks
```

If a Tea upload key has already been used for `com.teawithyou.app` in Play Console, keep using that exact key. Do not generate a replacement key.

If Tea has never been uploaded to Play and no Tea upload key exists yet, create it once:

```bash
mkdir -p /c/dev/keys
keytool -genkeypair -v \
  -keystore C:/dev/keys/tea-upload-key.jks \
  -keyalg RSA \
  -keysize 2048 \
  -validity 10000 \
  -alias upload
```

Back up the keystore securely. Never commit it.

## 2. android/key.properties

Local-only file:

```text
android/key.properties
```

Create it from the example if needed:

```bash
cp android/key.properties.example android/key.properties
```

Expected shape:

```properties
storePassword=YOUR_STORE_PASSWORD
keyPassword=YOUR_KEY_PASSWORD
keyAlias=upload
storeFile=C:/dev/keys/tea-upload-key.jks
```

Use forward slashes in `storeFile` on Windows.

Both the keystore and `key.properties` must remain out of Git. `android/.gitignore` excludes `key.properties`, `*.keystore`, and `*.jks`.

## 3. Build the release bundle

```bash
bash scripts/build_release.sh
```

The script checks the keystore path referenced by `android/key.properties`, then runs:

- `flutter clean`
- `flutter pub get`
- `flutter analyze`
- `flutter build appbundle --release`

Expected artifact:

```text
build/app/outputs/bundle/release/app-release.aab
```

## 4. Device QA

Known Android test device:

```text
R3CWC0JDAER
```

Normal QA:

```bash
flutter run -d R3CWC0JDAER
```

The AAB is for Play Console upload.

## 5. Launcher icon implementation

The working launcher icon is generated at Android build time from base64 text chunks in:

```text
android/app/launcher_icon_base64/
```

Gradle generates:

```text
mipmap-nodpi/tea_release_icon_v5.png
```

The manifest points to:

```text
@mipmap/tea_release_icon_v5
```

Do not restore old `tea_launcher_*.png` or `tea_release_icon.png` files without first checking `docs/PROJECT_HANDOFF.md`.

## 6. Closed testing

Follow `PLAY_CONSOLE_CLOSED_TESTING.md`.

For every later Play upload, increment the build number in `pubspec.yaml`.

Example:

```yaml
version: 1.0.0+4
```

## Security

Never commit or send:

- `C:\dev\keys\tea-upload-key.jks`
- `android/key.properties`
- any keystore password
