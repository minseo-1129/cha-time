# cha-time — Google Play closed testing checklist

## Build identity

- App name: `cha-time`
- Application ID: `com.teawithyou.app`
- Current version: `1.0.0+4`
- Artifact: Android App Bundle (`.aab`)

The package ID and existing upload key must stay unchanged because the app already has a Play upload history.

## Before upload

1. Pull latest `main`.
2. Confirm the existing signing files are present locally:
   - `C:\dev\keys\tea-upload-key.jks`
   - `android/key.properties`
3. Confirm the licensed voice font exists locally under `assets/fonts/`.
4. Run:

```bash
bash scripts/build_release.sh
```

5. Confirm:

```text
build/app/outputs/bundle/release/app-release.aab
```

6. Do not upload if analyze, tests, signing checks, font checks, or the AAB build fail.

## Play Console identity

Use the existing Play app with package:

```text
com.teawithyou.app
```

The user-facing product/store name should be `cha-time`. If Play Console still shows the old `Tea` name in the store listing, update the store listing title there separately; changing the Android launcher label does not automatically rewrite Play Store listing text.

## Closed/internal testing upload

Upload the new:

```text
app-release.aab
```

Version code `4` is intentionally higher than the previously uploaded version code `3`.

Suggested release note:

```text
cha-time v1.0 — prototype-aligned calendar, tea ritual, seasonal context and fortune flow.
```

## QA focus for +4

Check these before promoting the build:

- launcher displays `cha-time`
- Kyobo handwriting renders for the authored voice/input surfaces
- calendar shows today, finished/unfinished markers and visit count
- 6 sends empty one cup
- refill visibly restores the cup in stages
- finish shows saucer/blossom and opens the fortune card
- a finished past date can reopen its stored fortune
- relationship copy changes after visit thresholds
- local data survives app restart
- weather visual QA works with Dart defines (`clear`, `cloudy`, `rain`, `snow`)

## Every later upload

Increment the Android build number in `pubspec.yaml` (`+5`, `+6`, ...). Google Play rejects reuse of an existing version code.

## Keep private

Never commit:

- `C:\dev\keys\tea-upload-key.jks`
- `android/key.properties`
- keystore passwords
- production API credentials
