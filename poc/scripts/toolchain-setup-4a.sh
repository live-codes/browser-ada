#!/usr/bin/env bash
set -e
export DEBIAN_FRONTEND=noninteractive
apt-get install -y -qq python3 python3-pip xz-utils
if [ ! -d /opt/emsdk/.git ]; then
  git clone --depth 1 https://github.com/emscripten-core/emsdk.git /opt/emsdk
fi
cd /opt/emsdk
./emsdk install latest
./emsdk activate latest
# shellcheck disable=SC1091
source ./emsdk_env.sh
emcc --version | head -2
echo "EMCC=$(which emcc)"
echo "DONE stage4a"
