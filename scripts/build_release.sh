#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

if [[ ! -f "android/key.properties" ]]; then
  echo "Missing android/key.properties"
  echo "Copy android/key.properties.example to android/key.properties and fill in your upload key details."
  exit 1
fi

if [[ ! -f "android/upload-keystore.jks" ]]; then
  echo "Missing android/upload-keystore.jks"
  echo "Create it first with the keytool command in RELEASE_ANDROID.md."
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
