#!/usr/bin/env bash
export LLVMBIN=/usr/lib/llvm-21/bin
export PATH=$LLVMBIN:/usr/local/bin:/usr/bin:/bin
export LD_LIBRARY_PATH=/usr/lib/llvm-21/lib

ls -l /usr/bin/gnatbind-16 /usr/bin/gnatlink-16 2>&1
ln -sf /usr/bin/gnatbind-16 /usr/local/bin/x86_64-linux-gnu-gnatbind
ln -sf /usr/bin/gnatlink-16 /usr/local/bin/x86_64-linux-gnu-gnatlink
ln -sf /usr/bin/gcc-16 /usr/local/bin/x86_64-linux-gnu-gcc
ln -sf /usr/bin/g++-16 /usr/local/bin/x86_64-linux-gnu-g++
echo "--- symlinks ---"; ls -l /usr/local/bin/x86_64-linux-gnu-*

cd /tmp/tinyproj
rm -rf obj hello
gprbuild -P p.gpr 2>&1 | tail -6
echo "--- run ---"
./hello 2>&1

echo "=== driver in generated config ==="
grep -i 'driver' /tmp/g4.cgpr || true
