# Tea — Google Play closed testing checklist

## Build identity

- App name: Tea
- Application ID: `com.teawithyou.app`
- Version: `1.0.0+1`
- Artifact: Android App Bundle (`.aab`)

## Before the first upload

1. Pull the latest `main`.
2. Create the upload keystore once.
3. Create `android/key.properties`.
4. Run:
   ```bash
   bash scripts/build_release.sh
   ```
5. Confirm this file exists:
   ```text
   build/app/outputs/bundle/release/app-release.aab
   ```

## Play Console setup

Create the app as **Tea** and use the package/application ID:

```text
com.teawithyou.app
```

Then complete the required setup screens before publishing the closed-test release:

- App details / default language
- Store listing
- App icon and screenshots
- Privacy policy if required by the declarations you make
- Data safety
- App access
- Ads declaration
- Content rating
- Target audience / age declarations
- Any additional policy declarations shown by the Console

## Closed test

- Create a closed-testing track.
- Add the tester group/list.
- Upload `app-release.aab`.
- Add a short release note, for example:
  `Tea v1.0 — first closed testing build.`
- Review all warnings/errors.
- Start the closed test only after the release is accepted by the Console.

## For every later upload

Increment the build number in `pubspec.yaml`.

Example:

```yaml
version: 1.0.0+2
```

Google Play will reject a second bundle that reuses the same Android version code.

## Keep private

Never commit:

- `android/upload-keystore.jks`
- `android/key.properties`
- keystore passwords
