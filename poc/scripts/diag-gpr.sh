#!/usr/bin/env bash
export GNATBIN=/root/.local/share/alire/toolchains/gnat_native_16.1.0_9f74f58a/bin
export LLVMBIN=/usr/lib/llvm-21/bin
export PATH=$GNATBIN:$LLVMBIN:/usr/local/bin:/usr/bin:/bin
export LD_LIBRARY_PATH=/usr/lib/llvm-21/lib

echo "PATH=$PATH"
echo "--- which ---"
which gnatls gnatbind gnatmake gcc gprconfig gprbuild
echo "--- gnatls -v ---"
gnatls -v 2>&1 | head -8
echo "--- gnatls --version ---"
gnatls --version 2>&1 | head -2
echo "--- gprconfig --version ---"
gprconfig --version 2>&1
echo "--- gprconfig batch ---"
gprconfig --batch --target=x86_64-linux-gnu -o /tmp/g.cgpr 2>&1
echo "exit=$?"
echo "--- generated config ---"
cat /tmp/g.cgpr 2>/dev/null | head -40
echo "--- ls toolchain bin ---"
ls "$GNATBIN" | head -40
