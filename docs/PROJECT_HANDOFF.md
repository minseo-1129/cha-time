# cha-time — Project Handoff

> Read this first in a new chat. GitHub `main` is the source of truth; inspect the latest code before changing anything.

## Identity

- Product name: **cha-time**
- Repository: `minseo-1129/cha-time`
- Android application ID: `com.teawithyou.app`
- Current release version: `1.0.0+4`
- Local project path: `C:\dev\cha-time`
- Upload key: existing `C:\dev\keys\tea-upload-key.jks` (legacy filename; keep using the same key)

Do not change the Android application ID or replace the existing upload key. The app already has Play upload history.

Historical design filenames/copy may still say `Tea` or `소담`. The shipping app/store name is `cha-time`.

## Source of truth

Product/design reference:

- `design/sodam-prototype.html`
- `design/sodam-season-matrix.html`
- `design/README.md`

Flutter implementation:

- `lib/main.dart`
- `lib/cha_time_app.dart`

Release docs:

- `RELEASE_ANDROID.md`
- `PLAY_CONSOLE_CLOSED_TESTING.md`
- `TYPEFACE.md`

## Implemented v4 product flow

### Calendar

- calendar is the home screen
- month navigation
- today highlight
- unfinished day → raindrop
- finished day → blossom
- completed visit count (`n번째 잔`)
- today opens the current session
- finished past days with a stored fortune reopen that fortune card

### Tea ritual

- one reflection consumes one sip
- exactly 6 sends empty one cup
- user line appears under the cup
- response types in character by character
- weather can multiply typing speed
- no chat-bubble transcript

### Empty cup / refill

- `한 잔 더 마실래`
- `오늘 이만 마칠래`
- refill animates empty → partial → partial → full using the prototype timing steps
- refill gives a short local authored line

### Closing / fortune

- cup leaves
- saucer + blossom trace appear
- relationship-stage closing line appears
- tapping the blossom opens the paper fortune card
- fortune is stored locally and can be reopened from the finished calendar date

### Relationship progression

Completed visit count controls three voice stages:

- stage 1: ≤ 6
- stage 2: 7–20
- stage 3: 21+

Opening copy, response pool, CTA and closing copy vary by stage.

## Season × weather

Season is derived locally from the calendar:

- winter: Dec–Feb
- spring: Mar–May
- rainy season: Jun–Jul
- summer: Aug
- autumn: Sep–Nov

The Flutter port includes paper tone, tea tint, steam, light wash, rain/snow particles, weather typing multipliers, send-moment reactions, and special opening lines for selected season/weather combinations.

### Live weather boundary

Live weather is **not** connected yet. Production defaults to clear rather than inventing weather. QA can exercise visual states with:

```bash
flutter run --dart-define=CHA_TIME_WEATHER=clear
flutter run --dart-define=CHA_TIME_WEATHER=cloudy
flutter run --dart-define=CHA_TIME_WEATHER=rain
flutter run --dart-define=CHA_TIME_WEATHER=snow
```

Connecting real weather requires choosing a provider/data source and deciding whether location permission or a coarse/manual location model is appropriate.

## Generative text boundary

The prototype reserves generation for narrow end-of-session/fortune behavior. The Flutter client currently uses local authored fallbacks.

A production AI call is **not** hard-coded into the mobile app because API secrets must not ship in the client. Real generation requires a chosen provider plus a secure backend/server function. Normal reflection responses should remain constrained and local rather than becoming an open-ended chatbot.

## Persistence

Current storage key:

```text
cha_time_state_v2
```

The app migrates the previous `tea_sessions_v1` records when possible.

Stored state includes:

- completed visit count
- date
- finished/unfinished status
- sip count
- cups served
- fortune text
- update timestamp

## Typography

Voice typeface: **교보문고 손글씨 2025 이유빈**.

The font binary stays local under `assets/fonts/` unless its license explicitly permits redistribution. `scripts/build_release.sh` now refuses to build a release AAB if no `.ttf`/`.otf` is present, preventing a silent system-font fallback.

Calendar structural text intentionally remains sans-serif.

## Android release

```bash
cd /c/dev/cha-time
git pull origin main
bash scripts/build_release.sh
```

The script checks signing + font, then runs:

- `flutter clean`
- `flutter pub get`
- `flutter analyze`
- `flutter test`
- `flutter build appbundle --release`

Expected artifact:

```text
build/app/outputs/bundle/release/app-release.aab
```

## Security

Never commit or expose:

- `C:\dev\keys\tea-upload-key.jks`
- `android/key.properties`
- keystore passwords
- production API secrets
- font binaries whose license does not permit redistribution

## New-chat bootstrap

```text
Continue my Flutter app cha-time at GitHub repo `minseo-1129/cha-time`.
Read `docs/PROJECT_HANDOFF.md` and `design/README.md`, then inspect the latest `main` before changing anything.
Treat the design files as the product reference and the latest Flutter code/user instruction as authoritative where older Tea/소담 handoff text conflicts.
For approved implementation work, edit the repo directly and preserve `com.teawithyou.app` plus the existing Play upload key.
```
