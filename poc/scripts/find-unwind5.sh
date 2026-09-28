#!/usr/bin/env bash
NM=/usr/lib/llvm-21/bin/llvm-nm
echo "=== search all .a under emsdk upstream for _Unwind_CallPersonality ==="
find /opt/emsdk/upstream -name '*.a' 2>/dev/null | while read -r f; do
  if "$NM" "$f" 2>/dev/null | grep -q "_Unwind_CallPersonality"; then
    echo "FOUND: $f"
  fi
done
echo "=== also check libclang_rt / compiler-rt dirs ==="
find /opt/emsdk -name '*compiler_rt*.a' -o -name 'libclang_rt*' 2>/dev/null | head
echo "=== strings search in emscripten src for CallPersonality ==="
grep -rn "CallPersonality" /opt/emsdk/upstream/emscripten/src /opt/emsdk/upstream/emscripten/tools 2>/dev/null | head
