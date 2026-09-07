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

- `design/sodam-prototype.html` — calendar → tea session → finish → fortune card (the shipping app intentionally limits each day to one cup)
- `design/sodam-season-matrix.html` — season × weather visual and interaction rules
- `design/README.md` — porting notes and design decisions

`Tea` and `소담` may still appear inside historical design-reference filenames or copy. The shipping product name is **cha-time**.

## Flutter implementation

The current implementation is in:

- `lib/main.dart`
- `lib/cha_time_app.dart`
- `lib/weather_context.dart`
- `lib/season_specials.dart`

It includes calendar persistence, a strict one-cup-per-day 6-sip progression, closing/fortune flow, past finished-day fortune access, relationship progression, seasonal styling, live weather ambience, and migration from the previous `tea_sessions_v1` local storage format.

The six Season Matrix exceptions are implemented: 꽃비, 소나기, 갠 하늘, 찬비, 마른 햇빛, 첫눈.

## Voice font

The intended voice typeface is the locally licensed Kyobo Handwriting 2025 font. Keep the font binary in `assets/fonts/` on the release machine. Do not commit or redistribute it unless the license explicitly allows that.

The release script refuses to build an AAB when no `.ttf`/`.otf` exists in `assets/fonts/`, preventing an accidental system-font release.

## Live weather and rainy-season ambience

cha-time requests foreground approximate location while the app is open and sends the coordinate directly to Open-Meteo to retrieve current local weather plus a short recent/forecast precipitation window.

Latitude/longitude are not persisted in reflection records. The saved daily record keeps only the resulting season/weather context needed to reproduce that day's visual trace. If location permission, location services, or the network is unavailable, the app falls back to its normal calendar-season ambience without blocking the reflection flow.

The 장마 layer is data-driven rather than tied to fixed June/July dates. A sustained warm-rain pattern is inferred from recent + forecast Open-Meteo precipitation data. This is a cha-time ambience rule, not an official meteorological declaration of 장마.

When live weather is active, the app shows a small `Weather data by Open-Meteo` attribution link.

For visual QA, weather can still be overridden without changing production logic:

```bash
flutter run --dart-define=CHA_TIME_WEATHER=rain
```

Supported QA values: `clear`, `cloudy`, `rain`, `snow`.

## Generative text status

Generative AI is intentionally deferred. The current release uses constrained local authored/fallback responses and fortune lines. Do not place an OpenAI or other provider API key in the Flutter client; future AI should be connected through a secure backend/serverless endpoint.

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
