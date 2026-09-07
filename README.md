# cha-time

A quiet daily tea reflection ritual built with Flutter.

## Product identity

- App name: `cha-time`
- Android application ID: `com.teawithyou.app`
- Current version: `1.0.0+4`
- Repository: `minseo-1129/cha-time`

The Android application ID is already tied to the Play app and must not change. The existing upload key must also continue to be used for future Play uploads.

## Design source of truth

The interactive product reference lives in `design/`:

- `design/sodam-prototype.html` — calendar → tea session → refill/finish → fortune card
- `design/sodam-season-matrix.html` — season × weather visual and interaction rules
- `design/README.md` — porting notes and design decisions

`Tea` and `소담` may still appear inside historical design-reference filenames or copy. The shipping product name is **cha-time**.

## Flutter implementation

The current implementation is in:

- `lib/main.dart`
- `lib/cha_time_app.dart`

It includes calendar persistence, 6-sip cup progression, refill animation, closing/fortune flow, past finished-day fortune access, relationship progression, seasonal styling, weather visual states, and migration from the previous `tea_sessions_v1` local storage format.

## Voice font

The intended voice typeface is the locally licensed Kyobo Handwriting 2025 font. Keep the font binary in `assets/fonts/` on the release machine. Do not commit or redistribute it unless the license explicitly allows that.

The release script refuses to build an AAB when no `.ttf`/`.otf` exists in `assets/fonts/`, preventing an accidental system-font release.

## Weather integration status

Season selection is implemented from the local calendar. The weather visual system is implemented, but live weather data is not connected yet. Until a production weather provider is selected, the app defaults to `clear` and QA can exercise the other visual states with a Dart define, for example:

```bash
flutter run --dart-define=CHA_TIME_WEATHER=rain
```

Supported QA values: `clear`, `cloudy`, `rain`, `snow`.

## Generative text status

The app currently uses the prototype's local authored/fallback text. A production AI backend is intentionally not hard-coded into the client. Connecting generative last-line/fortune behavior requires a chosen backend/provider and secure server-side credentials.

## Release

```bash
bash scripts/build_release.sh
```

Expected artifact:

```text
build/app/outputs/bundle/release/app-release.aab
```

Release notes and Play steps:

- `RELEASE_ANDROID.md`
- `PLAY_CONSOLE_CLOSED_TESTING.md`
- `TYPEFACE.md`

GitHub `main` is the source of truth. Never commit signing secrets, keystores, passwords, or `android/key.properties`.
