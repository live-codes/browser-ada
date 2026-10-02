// Build the single-file IIFE bundle:
//   dist/ada-wasm.iife.js = UMD wrapper around (embedded HAC runtime + wrapper)
//
// The HAC runtime (hac-standalone.js) is a classic script that defines a
// `createHacModule` factory and embeds the wasm binary as base64. We wrap it so
// CommonJS globals are shadowed (its `module.exports` branch is skipped) and
// expose the resulting `AdaWasm` API as a global and as module.exports.

import { readFileSync, writeFileSync, mkdirSync } from 'node:fs';
import { fileURLToPath } from 'node:url';
import { dirname, join } from 'node:path';

const here = dirname(fileURLToPath(import.meta.url));
const pkgDir = join(here, '..');
const repoRoot = join(pkgDir, '..', '..');

const pkg = JSON.parse(readFileSync(join(pkgDir, 'package.json'), 'utf8'));
const runtimePath = join(repoRoot, 'poc', 'hac-wasm', 'hac-standalone.js');
const runtime = readFileSync(runtimePath, 'utf8');
const wrapper = readFileSync(join(pkgDir, 'src', 'index.js'), 'utf8');

if (!runtime.includes('var createHacModule=')) {
  throw new Error(
    `Unexpected runtime format in ${runtimePath}. ` +
      'Rebuild it with poc/scripts/build-hac.sh (expects a "var createHacModule=" global).',
  );
}

const banner =
  `/*! ${pkg.name} v${pkg.version} | ${pkg.license} | ` +
  'bundles HAC (MIT) and the GNAT/AdaWebPack WebAssembly runtime ' +
  '(GPL-3.0-or-later with the GCC Runtime Library Exception) */';

const bundle = `${banner}
(function (root, factory) {
  var api = factory();
  if (typeof module === "object" && module.exports) { module.exports = api; module.exports.default = api; }
  if (root) { root.AdaWasm = api; }
})(typeof globalThis !== "undefined" ? globalThis : (typeof self !== "undefined" ? self : this), function () {

var createHacModule = (function (module, exports, define) {
${runtime}
return createHacModule;
})(undefined, undefined, undefined);

${wrapper}

return AdaWasm;
});
`;

mkdirSync(join(pkgDir, 'dist'), { recursive: true });
writeFileSync(join(pkgDir, 'dist', 'ada-wasm.iife.js'), bundle);
writeFileSync(
  join(pkgDir, 'dist', 'index.d.ts'),
  readFileSync(join(pkgDir, 'src', 'index.d.ts'), 'utf8'),
);

console.log(
  `built dist/ada-wasm.iife.js (${(bundle.length / 1024 / 1024).toFixed(2)} MiB) ` +
    `from ${(runtime.length / 1024 / 1024).toFixed(2)} MiB runtime`,
);
