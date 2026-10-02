// Verifies that requiring the package root (via package.json "main") works.
const assert = require('node:assert');
const AdaWasm = require('..');

(async () => {
  const r = await AdaWasm.run(
    'with HAT; use HAT; procedure P is begin Put_Line ("via package main"); end P;',
  );
  assert.strictEqual(r.stdout, 'via package main\n');
  assert.strictEqual(r.exitCode, 0);
  console.log('require("..") ok');
})().catch((e) => {
  console.error(e);
  process.exit(1);
});
