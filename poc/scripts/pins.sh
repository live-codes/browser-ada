#!/usr/bin/env bash
echo "=== gnat-llvm fork HEAD ==="
git -C /opt/gnat-llvm rev-parse HEAD 2>/dev/null
git -C /opt/gnat-llvm log -1 --format='%ci %s' 2>/dev/null
echo "=== adawebpack fork HEAD ==="
git -C /opt/gnat-llvm/llvm-interface/adawebpack_src rev-parse HEAD 2>/dev/null
echo "=== bb-runtimes fork HEAD ==="
git -C /opt/gnat-llvm/llvm-interface/bb-runtimes rev-parse HEAD 2>/dev/null
git -C /opt/gnat-llvm/llvm-interface/bb-runtimes branch --show-current 2>/dev/null
echo "=== gcc HEAD ==="
git -C /opt/gnat-llvm/llvm-interface/gcc rev-parse HEAD 2>/dev/null
git -C /opt/gnat-llvm/llvm-interface/gcc describe --tags 2>/dev/null
echo "=== llvm-bindings HEAD ==="
git -C /opt/gnat-llvm/llvm-bindings rev-parse HEAD 2>/dev/null
echo "=== versions ==="
/opt/gnat-llvm/llvm-interface/bin/llvm-gcc -v 2>&1 | tail -1
/usr/lib/llvm-21/bin/clang --version 2>&1 | head -1
/opt/emsdk/upstream/emscripten/emcc --version 2>&1 | head -1
gcc-16 --version 2>&1 | head -1
alr --version 2>&1 | head -1
echo "=== HAC HEAD ==="
git -C /opt/hac rev-parse HEAD 2>/dev/null
