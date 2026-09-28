#!/usr/bin/env bash
# Stage 1: base packages, Alire + GNAT 16.1.0, LLVM/Clang 21.
set -e
export DEBIAN_FRONTEND=noninteractive

echo "### base packages"
apt-get update -qq
apt-get install -y -qq \
  wget curl zip unzip git make cmake ninja-build python3 python3-pip \
  bc lsb-release software-properties-common gnupg file pkg-config

echo "### Alire"
if [ ! -x /usr/local/bin/alr ]; then
  cd /opt
  wget -q https://github.com/alire-project/alire/releases/download/v2.1.1/alr-2.1.1-bin-x86_64-linux.zip -O alr.zip
  rm -rf alr-extract && mkdir alr-extract
  unzip -oq alr.zip -d alr-extract
  ALRBIN=$(find /opt/alr-extract -type f -name alr | head -1)
  cp "$ALRBIN" /usr/local/bin/alr
  chmod +x /usr/local/bin/alr
fi
alr --version

echo "### GNAT 16.1.0 via Alire"
alr -n toolchain --select gnat_native=16.1.0 || alr -n toolchain --select gnat_native=15.3.1
echo "--- installed toolchains ---"
alr toolchain || true
echo "--- locate gnatmake ---"
find /root /home -type f -name gnatmake 2>/dev/null | head
find /root /home -type d -name 'gnat_native*' 2>/dev/null | head

echo "### LLVM / Clang 21"
if ! command -v clang-21 >/dev/null 2>&1; then
  cd /opt
  wget -q https://apt.llvm.org/llvm.sh -O llvm.sh
  chmod +x llvm.sh
  ./llvm.sh 21 all
fi
echo "--- versions ---"
clang-21 --version 2>&1 | head -1
llvm-config-21 --version 2>&1 | head -1
wasm-ld-21 --version 2>&1 | head -1
ls /usr/lib/llvm-21/bin/ | grep -E '^(clang|llvm-config|wasm-ld|llvm-ranlib|llvm-ar|ld.lld)' | head
echo "DONE stage1"
