#!/usr/bin/env bash
set -euo pipefail

IMAGE="mahjong-flutter-builder"
APK_SRC="/app/build/app/outputs/flutter-apk/app-release.apk"

# Derive version from pubspec.yaml (strips build number: 1.0.0+1 → 1.0.0)
VERSION=$(grep '^version:' pubspec.yaml | sed 's/version:[[:space:]]*//' | sed 's/+.*//')
APK_DST="$(pwd)/mahjong-${VERSION}.apk"

echo "==> Building Docker image (version ${VERSION})..."
docker build -t "$IMAGE" .

echo "==> Extracting APK..."
container=$(docker create "$IMAGE")
docker cp "$container:$APK_SRC" "$APK_DST"
docker rm "$container" > /dev/null

echo ""
echo "Done! APK saved to: $APK_DST"
