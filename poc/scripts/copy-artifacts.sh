#!/usr/bin/env bash
set -e
DEST=/mnt/d/DevWork/live-codes/browser-ada/poc/adawebpack-smoke
mkdir -p "$DEST"
cp /root/awtest/main.wasm "$DEST/main.wasm"
cp /opt/awp/adawebpack/share/adawebpack/adawebpack.mjs "$DEST/adawebpack.mjs"
ls -l "$DEST"
echo "--- mjs lines ---"
wc -l "$DEST/adawebpack.mjs"
