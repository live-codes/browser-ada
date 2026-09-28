#!/usr/bin/env bash
# Stage 2: fetch gnat-llvm fork, GCC 16.1.0, llvm-bindings, adawebpack fork, bb-runtimes.
set -e

export GNATBIN=/root/.local/share/alire/toolchains/gnat_native_16.1.0_9f74f58a/bin
export LLVMBIN=/usr/lib/llvm-21/bin
export PATH=$GNATBIN:$LLVMBIN:/usr/local/bin:/usr/bin:/bin
export LD_LIBRARY_PATH=/usr/lib/llvm-21/lib

ROOT=/opt/gnat-llvm
mkdir -p /opt
if [ ! -d "$ROOT/.git" ]; then
  git clone --depth 1 https://github.com/ovenpasta/gnat-llvm.git "$ROOT"
fi
cd "$ROOT"

echo "### llvm-bindings"
[ -d llvm-bindings/.git ] || git clone --depth 1 https://github.com/AdaCore/llvm-bindings.git llvm-bindings

echo "### GCC 16.1.0 (shallow) - large download"
if [ ! -d llvm-interface/gcc/.git ]; then
  git clone --branch releases/gcc-16.1.0 --depth 1 https://github.com/gcc-mirror/gcc.git llvm-interface/gcc
fi

echo "### adawebpack fork"
[ -d llvm-interface/adawebpack_src/.git ] || \
  git clone --depth 1 https://github.com/ovenpasta/adawebpack.git llvm-interface/adawebpack_src

echo "### bb-runtimes fork (gnat-fsf-15)"
[ -d llvm-interface/bb-runtimes/.git ] || \
  git clone -b gnat-fsf-15 --depth 1 https://github.com/ovenpasta/bb-runtimes.git llvm-interface/bb-runtimes

cd "$ROOT/llvm-interface"

echo "### apply GCC 16 patches"
for p in gcc-16-repinfo-accessors gcc-16-allow-reraise-no-propagation gcc-16-wasm-eh-raise-gcc; do
  if [ -f "patches/$p.patch" ]; then
    if git -C gcc apply --reverse --check "patches/$p.patch" >/dev/null 2>&1; then
      echo "  $p already applied"
    else
      git -C gcc apply "patches/$p.patch" && echo "  applied $p"
    fi
  else
    echo "  WARNING: patches/$p.patch missing"
  fi
done

echo "### symlinks"
ln -sfn "$(pwd)/gcc/gcc/ada" gnat_src
ln -sfn "$(pwd)/bb-runtimes/gnat_rts_sources/include/rts-sources/" rts-sources

echo "### Makefile.target from adawebpack"
if [ -e Makefile.target ] && [ ! -L Makefile.target ]; then
  mv Makefile.target Makefile.target.orig
fi
ln -sfn "$(pwd)/adawebpack_src/source/rtl/Makefile.target" Makefile.target

echo "### layout"
ls -la | sed -n '1,40p'
echo "--- patches present ---"
ls patches 2>/dev/null || true
echo "--- gnat_src ---"; ls -l gnat_src | head -2
echo "--- rts-sources ---"; ls -ld rts-sources; ls rts-sources | head
echo "--- bindings ---"; ls -ld ../llvm-bindings
echo "DONE stage2"
