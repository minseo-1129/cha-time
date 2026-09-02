# Tea — Google Play closed testing checklist

## Build identity

- App name: Tea
- Application ID: `com.teawithyou.app`
- Current version: `1.0.0+3`
- Artifact: Android App Bundle (`.aab`)

## Before upload

1. Pull latest `main`.
2. Read `docs/PROJECT_HANDOFF.md` for current release status.
3. Confirm local upload signing files exist.
4. Run:
   ```bash
   bash scripts/build_release.sh
   ```
5. Confirm:
   ```text
   build/app/outputs/bundle/release/app-release.aab
   ```
6. Do not upload if the release build did not complete successfully.

## Play Console identity

Use:

```text
Tea
com.teawithyou.app
```

Complete all required Play Console setup/declaration screens that are shown for the account and app before publishing the closed-test release.

Typical items include:

- store listing
- app details/default language
- screenshots and app icon
- privacy/data safety declarations
- app access
- ads declaration
- content rating
- target audience
- any current Play policy declarations

## Closed test

- Create/use a closed-testing track.
- Add the tester group/list.
- Upload `app-release.aab`.
- Add a short release note, e.g.:
  `Tea v1.0 — first closed testing build.`
- Resolve blocking warnings/errors.
- Start the test only after the release is accepted.

## Every later upload

Increment the Android build number in `pubspec.yaml`.

Example:

```yaml
version: 1.0.0+4
```

Google Play will reject a later bundle that reuses an existing version code.

## Keep private

Never commit:

- `android/upload-keystore.jks`
- `android/key.properties`
- keystore passwords
