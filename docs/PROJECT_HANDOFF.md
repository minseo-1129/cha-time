# Tea — Project Handoff

> **Read this first in a new chat.**
>
> GitHub is the source of truth. Before changing anything, inspect the latest `main` because the repository may have changed after this handoff was written.

## Copy/paste bootstrap prompt for a new chat

```text
Continue my Flutter project Tea at GitHub repo `minseo-1129/doodle`.

First read `docs/PROJECT_HANDOFF.md` and inspect the latest `main`. Treat GitHub as the source of truth because I may have changed things since the previous chat.

When I ask for an implementation change, modify the repo directly, commit it, and push to `main` instead of only giving me instructions.

My Android test device is `R3CWC0JDAER`.

After reviewing the repo, I will give you the next task.
```

## Working agreement

- Repository: `minseo-1129/doodle` (private)
- Product name: **Tea**
- Android application ID: `com.teawithyou.app`
- Main implementation: `lib/main.dart`
- Primary branch: `main`
- Prefer direct repo edits + commits for approved implementation work.
- Do not commit signing secrets, keystores, passwords, or `android/key.properties`.
- For local testing, the known Android device ID is `R3CWC0JDAER`.
- Typical local project path: `C:\dev\doodle`.
- Typical terminal: Git Bash on Windows.
- If this document conflicts with current code or a newer user instruction, **current GitHub `main` and the latest user instruction win**.

## Current repository snapshot

At the time this file was created:

- Latest `main`: `f1cc9c426c57762342eae5ed1e834dc09d019062`
- Version in `pubspec.yaml`: **1.0.0+3**
- App name: **Tea**
- Package: `com.teawithyou.app`
- Release signing setup exists locally and is intentionally excluded from Git.

### Important release status

The launcher icon is now visibly working on the Samsung test device.

The last release build attempt **before** commit `f1cc9c4` failed in `:app:mergeReleaseResources` because several old/corrupted PNG files were still present under Android `res/` even though they were no longer used.

Commit `f1cc9c4` removed those obsolete resources and kept the new launcher path.

**The next release action is to rerun:**

```bash
cd /c/dev/doodle
git pull origin main
bash scripts/build_release.sh
```

Do not claim the current AAB is release-ready until that post-cleanup build is confirmed successful.

If successful, expected output:

```text
build/app/outputs/bundle/release/app-release.aab
```

## Product concept

Tea is a quiet, minimalist daily reflection ritual.

The emotional stance is:

- attentive, not possessive
- brief, not chatty
- never therapy-like
- never advice-giving
- no guilt language such as “I missed you”
- the system acknowledges rather than interprets or coaches

v1 does **not** use an LLM. Responses are local authored strings.

Future AI, if added, should only classify a response type and select/compose from constrained local language. It should not become an open-ended therapist/chat companion.

## Ritual interaction contract

### Fresh session opening

Fresh Tea entry currently follows:

1. blank/quiet moment
2. cup fades in
3. short pause
4. `오늘은 어떤 하루였어?` types in character by character

Current timing in code:

- blank hold: ~220 ms
- cup fade: 360 ms
- wait after cup appears: ~520 ms
- typewriter:
  - normal chars: 95–149 ms
  - spaces: 60–99 ms
  - punctuation: 190–249 ms

### Per-message rhythm

For each send:

1. user message appears immediately
2. previous system response disappears
3. ~340 ms quiet hold
4. tea level drops one exact step
5. ~430 ms hold
6. system response begins typing

System response candidates:

- `그랬구나.`
- `그런 일이 있었구나.`
- `응, 듣고 있어.`
- `천천히 말해도 돼.`
- `(호로록)`

The typed system response must remain plain `Text`. Do **not** wrap changing typewriter text in an `AnimatedSwitcher`; that previously caused ghosting/crossfade trails.

The most recent user utterance appears below the cup. There is no chat transcript and no chat bubble UI.

### Cup progression

Exactly **6 sends consume one cup**:

```text
full
→ 5/6
→ 4/6
→ 3/6
→ 2/6
→ 1/6
→ empty
```

Cup visual width is fixed at **225 px** and should not resize because of keyboard or state changes.

Current assets:

- `assets/images/tea_bowl_v1.png`
- `assets/images/tea_bowl_5of6.png`
- `assets/images/tea_bowl_4of6.png`
- `assets/images/tea_bowl_3of6.png`
- `assets/images/tea_bowl_2of6.png`
- `assets/images/tea_bowl_1of6.png`
- `assets/images/tea_bowl_empty.png`

### Empty cup

After the final typed response, Tea waits ~520 ms and enters the empty-cup state.

System text:

```text
잔이 비었어요
```

Actions:

- filled pale-green: `한 잔 더 마실래`
- outlined: `오늘 이만 마칠래`

Refill is immediate:

- resets sip count to full
- no refill sentence
- no special refill animation

### Finish state

When finishing:

- cup is removed
- same-angle saucer appears
- blossom trace appears
- after ~620 ms, closing line appears above it:

```text
내일 또 들러줘.
```

Assets:

- `assets/images/closing_saucer.png`
- `assets/images/trace_blossom.png`

## Input behavior

Current hint:

```text
천천히 생각나는 대로
```

Keep normal `TextField` hint behavior.

Do not restore the abandoned custom hint/focus-listener implementation.

Current input layout:

- horizontal inset: 28 px
- bottom when keyboard closed: 52 px
- bottom when keyboard open: keyboard height + 14 px
- min height: 52 px
- max height: 110 px
- 1–3 lines

Send control is a PNG UI asset, not a clean Material/system icon:

- `assets/ui/send_default.png`
- `assets/ui/send_disabled.png`

## Calendar home

Calendar is the app home screen.

Navigation:

- Calendar has no back arrow.
- Only **today** is tappable into Tea.
- Tea top-right calendar PNG returns to Calendar.
- Calendar reloads persisted state after returning.

Status display:

- no session → date only
- unfinished session → blue raindrop
- finished session → blossom

Markers are deliberately slightly handmade with deterministic offset/rotation.

There are **no date cards** and no chat-bubble/date-card backgrounds.

### Current calendar composition

Current hierarchy:

```text
month header
→ reserved seasonal/weather illustration window
→ weekday row
→ month grid
```

The illustration window is currently intentionally empty and fixed-height (~112 px). Future content may include rain, snow, seasonal leaves, 매화, etc. It should remain a stable layout region so seasonal art does not push the calendar around.

Current top area:

- calendar outer horizontal padding: 28 px
- top padding inside SafeArea: 24 px
- header height: 48 px

Weekday row is intentionally typographically distinct from date numbers.

Today uses a stronger but quiet sage circular highlight.

## Persistence model

Persistence uses `shared_preferences` via `SharedPreferencesAsync`.

Storage key:

```text
tea_sessions_v1
```

Session records contain:

- `dateStarted`
- `startedAt`
- `endedAt`
- `sipCount`
- `cupsServed`
- `finished`
- `phase`
- `systemText`
- `lastUserMessage`

A session belongs to the **date it started**, even if it crosses midnight.

On app/session reopen:

- latest unfinished session is restored first
- otherwise today’s record is restored
- finished session restores the closing state

Full conversation history is intentionally not persisted.

## Visual language

Avoid:

- photorealistic lifestyle imagery
- glossy Material UI
- clean/system-looking iconography where handmade assets already exist
- chat bubbles
- excessive borders/cards

Preferred direction:

- pale East Asian print / risograph / colored-pencil / paper feeling
- sparse composition
- delicate imperfect line art
- off-white cream
- pale blue
- sage/young green
- pale pink/brown
- quiet brown-gray linework

Core palette references:

- background: `#FAF7F2`
- sage: `#B8C09A`
- blue: `#A9BDD6`
- pink: `#E7C3C6`
- warm gray: `#D7CEC3`
- line/text gray: `#A69D93`

## Typography

The Tea “voice” typeface is **교보문고 손글씨 2025 이유빈**.

Runtime loading is handled by `TeaFonts.loadVoice()`, which scans `assets/fonts/` and prefers the 2025/Kyobo font.

Current voice-font usage includes:

- opening/system responses
- submitted user text
- text input
- input hint
- empty-cup text
- closing line
- action labels

Calendar structural text remains a quiet sans-serif.

Do not switch the whole calendar to handwriting.

## PNG UI controls

Important controls intentionally use organic PNG artwork:

- Tea calendar button: `assets/ui/calendar_default.png`
- send: `assets/ui/send_default.png`
- send disabled: `assets/ui/send_disabled.png`
- month previous: `assets/ui/calendar_prev_default.png`
- month next: `assets/ui/calendar_next_default.png`

Pressed feedback is handled in Flutter (scale/opacity), with no Material ripple.

## Android launcher icon — important postmortem

This area caused repeated problems. Read before changing launcher resources.

### What actually went wrong

Several PNG binaries committed through earlier GitHub operations were corrupted/truncated. Android still packaged them, but the extracted launcher image was effectively a blank cream square.

The icon itself was not a Flutter `pubspec assets` problem and not an SVG problem.

### Current solution

The visible icon has been confirmed working on the Samsung test device.

The launcher PNG is reconstructed at Android build time from text-safe base64 chunks stored in:

```text
android/app/launcher_icon_base64/
```

Gradle task:

```text
generateTeaLauncherIcon
```

generates:

```text
build/generated/tea_launcher_res/mipmap-nodpi/tea_release_icon_v5.png
```

The Android manifest points both icon fields to:

```text
@mipmap/tea_release_icon_v5
```

Do not casually replace this with one of the old `tea_launcher_*.png` resources.

Commit `f1cc9c4` removed obsolete/corrupted Android PNG launcher/splash resources so AAPT2 does not try to compile them.

Splash remains intentionally minimal/blank cream.

## Android release identity

Current:

- label: `Tea`
- application ID: `com.teawithyou.app`
- version: `1.0.0+3`
- target/compile SDK comes from current Flutter Android config
- signed release build script: `scripts/build_release.sh`

Release signing files are local only:

- `android/upload-keystore.jks`
- `android/key.properties`

Never commit or expose them.

## Useful commands

### Pull and run on the Samsung device

```bash
cd /c/dev/doodle
git pull origin main
flutter clean
flutter pub get
flutter run -d R3CWC0JDAER
```

### Build signed release AAB

```bash
cd /c/dev/doodle
git pull origin main
bash scripts/build_release.sh
```

### ADB path when Git Bash cannot find adb

```bash
ADB="/c/Users/USER/AppData/Local/Android/Sdk/platform-tools/adb.exe"
"$ADB" devices
```

### Exact installed package check

```bash
"$ADB" shell pm list packages | tr -d '\r' | grep -Fx "package:com.teawithyou.app"
```

## Release freeze guidance

Once `scripts/build_release.sh` succeeds after `f1cc9c4`:

1. confirm the generated AAB exists
2. optionally do a final device smoke test
3. avoid visual refactors before Play upload
4. increment Android build number for every later Play upload
5. preserve package ID `com.teawithyou.app`

## Future ideas intentionally not implemented yet

- seasonal/weather ambience in the calendar illustration window
- rain animation
- winter snow
- 매화 / seasonal motifs
- relationship/“days together” evolution
- optional constrained AI response classification

Relationship/seasonal progression should be based on **days together**, not the amount the user disclosed.

## First thing to do in the next chat

1. Read this file.
2. Inspect latest GitHub `main`.
3. Check whether the post-`f1cc9c4` release build succeeded.
4. Then follow the user’s next task and commit approved implementation directly to `main`.
