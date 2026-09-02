# Tea

A quiet daily tea reflection ritual built with Flutter.

## Start here

For project continuity, architecture, product behavior, release state, and the exact prompt to use in a new ChatGPT conversation, read:

- [docs/PROJECT_HANDOFF.md](docs/PROJECT_HANDOFF.md)
- [RELEASE_ANDROID.md](RELEASE_ANDROID.md)
- [PLAY_CONSOLE_CLOSED_TESTING.md](PLAY_CONSOLE_CLOSED_TESTING.md)
- [TYPEFACE.md](TYPEFACE.md)

## Android identity

- App name: `Tea`
- Application ID: `com.teawithyou.app`
- Current version: `1.0.0+3`

## Run on the known test device

```bash
flutter run -d R3CWC0JDAER
```

## Build signed release bundle

```bash
bash scripts/build_release.sh
```

Expected artifact:

```text
build/app/outputs/bundle/release/app-release.aab
```

GitHub `main` is the source of truth. Do not commit signing secrets.
