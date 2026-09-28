#!/usr/bin/env bash
echo "=== cpu/mem/disk ==="
nproc
free -h | head -2
df -h / /opt 2>/dev/null
echo "=== existing gnat/gcc ==="
which gcc gnat gnatmake 2>&1
gcc --version 2>&1 | head -1
echo "=== apt candidates ==="
for p in gcc-16 gnat-16 gcc-15 gnat-15 gnat gprbuild emscripten llvm-21-dev clang-21 libclang-21-dev llvm-21 lld-21; do
  printf '%-16s: %s\n' "$p" "$(apt-cache policy "$p" 2>/dev/null | grep Candidate | head -1)"
done
