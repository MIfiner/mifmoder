#!/usr/bin/env bash
set -euo pipefail

echo "============================================="
echo "   Building LightGram Desktop for Linux      "
echo "============================================="

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
BUILD_DIR="${ROOT_DIR}/build"

mkdir -p "${BUILD_DIR}"
cd "${BUILD_DIR}"

cmake -G Ninja \
    -DCMAKE_BUILD_TYPE=Release \
    ..

ninja lightgram-desktop test_lightgram

echo "Running automated test suite..."
QT_QPA_PLATFORM=offscreen ./test_lightgram

echo "Packaging .deb and .tar.gz distributions..."
cpack -G "TGZ;DEB"

echo "============================================="
echo " Linux build and packages ready in ${BUILD_DIR}"
echo "============================================="
ls -lh "${BUILD_DIR}"/LightGram-*
