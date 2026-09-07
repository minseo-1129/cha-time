# cha-time — Android release checklist

## Release identity

- App name: `cha-time`
- Application ID: `com.teawithyou.app`
- Version: `1.0.0+4`
- App data remains local on-device.

> The application ID is already tied to the Play app. Do not change `com.teawithyou.app`.

## 1. Existing upload keystore

Keep using the same upload key that was used for the existing Play app:

```text
C:\dev\keys\tea-upload-key.jks
```

The filename is legacy/internal only. Do **not** generate a replacement key just to rename it.

Git Bash path:

```text
C:/dev/keys/tea-upload-key.jks
```

Back it up securely. Never commit it.

## 2. android/key.properties

Local-only file:

```text
android/key.properties
```

Expected shape:

```properties
storePassword=YOUR_STORE_PASSWORD
keyPassword=YOUR_KEY_PASSWORD
keyAlias=upload
storeFile=C:/dev/keys/tea-upload-key.jks
```

Use forward slashes in `storeFile` on Windows. `android/.gitignore` excludes signing files.

## 3. Voice font

A release build now requires a local `.ttf` or `.otf` under:

```text
assets/fonts/
```

Use your licensed Kyobo Handwriting 2025 font file. The binary should stay local unless its license explicitly permits redistribution.

This requirement prevents a release AAB from silently falling back to the Android system font.

## 4. Build the release bundle

From the project root:

```bash
bash scripts/build_release.sh
```

The script checks the signing key and voice font, then runs:

- `flutter clean`
- `flutter pub get`
- `flutter analyze`
- `flutter test`
- `flutter build appbundle --release`

Expected artifact:

```text
build/app/outputs/bundle/release/app-release.aab
```

## 5. Device QA

Normal Android QA:

```bash
flutter run
```

To exercise weather visuals before live-weather integration exists:

```bash
flutter run --dart-define=CHA_TIME_WEATHER=rain
flutter run --dart-define=CHA_TIME_WEATHER=snow
```

Supported QA values are `clear`, `cloudy`, `rain`, and `snow`.

## 6. Play upload

The previous Play upload used version code `3`, so this release uses:

```yaml
version: 1.0.0+4
```

Upload only:

```text
build/app/outputs/bundle/release/app-release.aab
```

Do not upload the keystore or `key.properties`.

## 7. Launcher icon implementation

The working launcher icon is still generated during Android build from the existing base64 chunks in:

```text
android/app/launcher_icon_base64/
```

The Android resource name still contains the historical `tea_` prefix. That internal resource name does not affect the displayed app name, which is `cha-time`.

## External integrations not yet hard-coded

- Live weather: the visual/interaction system exists, but a production weather data provider still needs to be chosen and connected.
- Generative last-line/fortune text: the UI and fallback behavior exist, but production AI should be called through a secure backend, not with a secret embedded in the Flutter client.

## Security

Never commit or send publicly:

- `C:\dev\keys\tea-upload-key.jks`
- `android/key.properties`
- keystore passwords
- production API secrets
