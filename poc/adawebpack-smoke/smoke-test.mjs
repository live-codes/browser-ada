// Smoke test: instantiate the Ada->wasm module and call exported Ada functions.
import { readFileSync } from 'node:fs';
import { fileURLToPath } from 'node:url';
import * as AdaWebPack from './adawebpack.mjs';

const wasmPath = fileURLToPath(new URL('./main.wasm', import.meta.url));
const bytes = readFileSync(wasmPath);

const { instance } = await WebAssembly.instantiate(bytes, { env: AdaWebPack.imports });
AdaWebPack.initialize(instance);

console.log('ada_add(2, 3)  =', instance.exports.ada_add(2, 3));
console.log('ada_fib(10)    =', instance.exports.ada_fib(10));
console.log('ada_fib(20)    =', instance.exports.ada_fib(20));
console.log('ada_try_raise(1) =', instance.exports.ada_try_raise(1));
console.log('ada_try_raise(0) =', instance.exports.ada_try_raise(0));
