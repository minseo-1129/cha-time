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
  echo "For the standard local layout, use: C:/dev/keys/tea-upload-key.jks"
  exit 1
fi

echo "==> Cleaning"
flutter clean

echo "==> Fetching packages"
flutter pub get

echo "==> Static analysis"
flutter analyze

echo "==> Building signed Android App Bundle"
flutter build appbundle --release

echo
echo "Done."
echo "AAB: build/app/outputs/bundle/release/app-release.aab"
