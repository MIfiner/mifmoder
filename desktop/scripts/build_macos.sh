#!/usr/bin/env bash
set -euo pipefail

echo "============================================="
echo "   Building LightGram Desktop for macOS      "
echo "============================================="

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
BUILD_DIR="${ROOT_DIR}/build_mac"

mkdir -p "${BUILD_DIR}"
cd "${BUILD_DIR}"

cmake -G Ninja \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_OSX_ARCHITECTURES="arm64;x86_64" \
    -DCMAKE_OSX_DEPLOYMENT_TARGET="12.0" \
    ..

ninja lightgram-desktop test_lightgram

echo "Running automated test suite..."
QT_QPA_PLATFORM=offscreen ./test_lightgram

echo "Packaging macOS DMG and Bundle..."
cpack -G "DragNDrop;TGZ"

echo "============================================="
echo " macOS Universal2 build complete!"
echo "============================================="
ls -lh "${BUILD_DIR}"/LightGram-*
