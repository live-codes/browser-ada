#!/usr/bin/env bash
export GNATBIN=/root/.local/share/alire/toolchains/gnat_native_16.1.0_9f74f58a/bin
export LLVMBIN=/usr/lib/llvm-21/bin
export PATH=$GNATBIN:$LLVMBIN:/usr/local/bin:/usr/bin:/bin

echo "=== GNAT block in compilers.xml ==="
awk '/GNAT/{f=1} f{print} /<\/compiler_description>/{if(f){f=0; print "----"}}' /usr/share/gprconfig/compilers.xml | head -60

echo "=== gnatls -v full ==="
gnatls -v 2>&1 | head -20

echo "=== gcc -dumpmachine ==="
gcc -dumpmachine

echo "=== gprconfig no target ==="
gprconfig --batch -o /tmp/g_none.cgpr 2>&1; grep -i 'Driver\|Toolchain_Version' /tmp/g_none.cgpr | head
echo "=== gprconfig x86_64-pc-linux-gnu ==="
gprconfig --batch --target=x86_64-pc-linux-gnu -o /tmp/g_pc.cgpr 2>&1; grep -i 'Driver\|Toolchain_Version' /tmp/g_pc.cgpr | head
echo "=== gprconfig x86_64-linux-gnu ==="
gprconfig --batch --target=x86_64-linux-gnu -o /tmp/g_lin.cgpr 2>&1; grep -i 'Driver\|Toolchain_Version' /tmp/g_lin.cgpr | head
