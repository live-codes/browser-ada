#!/usr/bin/env bash
set -e
cd /opt/gnat-llvm/llvm-interface
P="$(pwd)/patches"
for p in gcc-16-repinfo-accessors gcc-16-allow-reraise-no-propagation gcc-16-wasm-eh-raise-gcc; do
  if [ -f "$P/$p.patch" ]; then
    if git -C gcc apply --reverse --check "$P/$p.patch" >/dev/null 2>&1; then
      echo "already applied: $p"
    else
      git -C gcc apply "$P/$p.patch" && echo "applied: $p"
    fi
  else
    echo "MISSING: $P/$p.patch"
  fi
done
echo "--- gcc status ---"
git -C gcc status --short | head -30
