#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

KEY_PROPERTIES="android/key.properties"

if [[ ! -f "$KEY_PROPERTIES" ]]; then
  echo "Missing android/key.properties"
  echo "Copy android/key.properties.example to android/key.properties and fill in your upload key details."
  exit 1
fi

STORE_FILE="$(sed -n 's/^storeFile=//p' "$KEY_PROPERTIES" | tail -n 1 | tr -d '\r')"

if [[ -z "$STORE_FILE" ]]; then
  echo "Missing storeFile in android/key.properties"
  exit 1
fi

KEYSTORE_PATH="$STORE_FILE"
if [[ ! "$KEYSTORE_PATH" =~ ^[A-Za-z]:/ && "$KEYSTORE_PATH" != /* ]]; then
  KEYSTORE_PATH="android/app/$KEYSTORE_PATH"
fi

if [[ ! -f "$KEYSTORE_PATH" ]]; then
  echo "Missing upload keystore: $STORE_FILE"
  echo "Keep using the existing Play upload key. Standard local path: C:/dev/keys/tea-upload-key.jks"
  exit 1
fi

VOICE_FONT="$(find assets/fonts -maxdepth 1 -type f \( -iname '*.ttf' -o -iname '*.otf' \) -print -quit 2>/dev/null || true)"
if [[ -z "$VOICE_FONT" ]]; then
  echo "Missing cha-time voice font in assets/fonts/"
  echo "Place your licensed local Kyobo Handwriting 2025 font there before a release build."
  echo "The font binary stays local and must not be committed unless its license explicitly permits redistribution."
  exit 1
fi

echo "==> Voice font: $VOICE_FONT"
echo "==> Cleaning"
flutter clean

echo "==> Fetching packages"
flutter pub get

echo "==> Static analysis"
flutter analyze

echo "==> Tests"
flutter test

echo "==> Building signed Android App Bundle"
flutter build appbundle --release

echo
echo "Done."
echo "AAB: build/app/outputs/bundle/release/app-release.aab"
