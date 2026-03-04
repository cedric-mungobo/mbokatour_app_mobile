#!/usr/bin/env bash
set -euo pipefail

FULL_CHECK=false
if [[ "${1:-}" == "--full" ]]; then
  FULL_CHECK=true
fi

echo "==> flutter pub get"
flutter pub get

echo "==> flutter analyze"
flutter analyze

echo "==> flutter test"
flutter test

if [[ "$FULL_CHECK" == "true" ]]; then
  echo "==> flutter build appbundle --release"
  flutter build appbundle --release

  echo "==> flutter build ios --release --no-codesign"
  flutter build ios --release --no-codesign
fi

echo "Release checklist OK"
