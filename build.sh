#!/usr/bin/env bash
set -euo pipefail

IMAGE="mahjong-flutter-builder"
APK_SRC="/app/build/app/outputs/flutter-apk/app-release.apk"
APK_DST="$(pwd)/app-release.apk"

echo "==> Building Docker image..."
docker build -t "$IMAGE" .

echo "==> Extracting APK..."
container=$(docker create "$IMAGE")
docker cp "$container:$APK_SRC" "$APK_DST"
docker rm "$container" > /dev/null

echo ""
echo "Done! APK saved to: $APK_DST"
