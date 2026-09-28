#!/usr/bin/env bash
set -e
export PATH=/opt/awp/adawebpack/bin:/usr/bin:/bin
cd /root/awtest/.objs
RTS=/opt/awp/adawebpack/lib/rts-native/adalib
wasm-ld --export-all --allow-undefined --no-entry \
  -o /root/awtest/main.wasm \
  main.o b__main.o demo.o \
  $RTS/libgnat.a
echo "LINK_OK"
file /root/awtest/main.wasm
ls -l /root/awtest/main.wasm

echo "=== exports ==="
wasm-ld --version >/dev/null 2>&1 || true
node -e '
const fs = require("fs");
const buf = fs.readFileSync("/root/awtest/main.wasm");
WebAssembly.compile(buf).then(m => {
  console.log("imports:", WebAssembly.Module.imports(m));
  console.log("exports:", WebAssembly.Module.exports(m).map(e => e.name + ":" + e.kind).join(", "));
}).catch(e => { console.error("compile error:", e.message); process.exit(1); });
'
