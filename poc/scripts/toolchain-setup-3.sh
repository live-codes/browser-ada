#!/usr/bin/env bash
# Stage 3 (retry): build GNAT-LLVM compiler with system GCC/GNAT 16 + LLVM 21.
set -o pipefail
export LLVMBIN=/usr/lib/llvm-21/bin
export PATH=$LLVMBIN:/usr/local/bin:/usr/bin:/bin
export LD_LIBRARY_PATH=/usr/lib/llvm-21/lib

cd /opt/gnat-llvm/llvm-interface
echo "=== make build ==="
make build PROCS=6 LLVM_CONFIG=llvm-config-21 CLANG_LINK_LIB=clang-cpp GNATMAKE=gnatmake-16 2>&1 \
  | tee /tmp/gnatllvm-build.log
echo "MAKE_EXIT=${PIPESTATUS[0]}"
echo "=== bin ==="
ls -l bin 2>&1 | head -40
echo "=== llvm-gcc -v ==="
./bin/llvm-gcc -v 2>&1 | head -5
echo "DONE stage3"
