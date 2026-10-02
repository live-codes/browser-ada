// End-to-end tests for the built bundle, in Node (no browser).
const assert = require('node:assert');
const AdaWasm = require('../dist/ada-wasm.iife.js');

(async () => {
  assert.strictEqual(typeof AdaWasm.createRuntime, 'function');
  assert.strictEqual(typeof AdaWasm.run, 'function');
  assert.strictEqual(globalThis.AdaWasm, AdaWasm, 'bundle must also set the global');

  // 1. stdout + exitCode
  let r = await AdaWasm.run(
    'with HAT; use HAT;\nprocedure Hello is begin Put_Line ("hello"); end Hello;',
  );
  assert.strictEqual(r.stdout, 'hello\n');
  assert.strictEqual(r.stderr, '');
  assert.strictEqual(r.exitCode, 0);

  // 2. stdin
  r = await AdaWasm.run(
    'with HAT; use HAT;\nprocedure Echo is V : VString; begin Get_Line (V); Put_Line ("echo: " & V); end Echo;',
    'world\n',
  );
  assert.strictEqual(r.stdout, 'echo: world\n');

  // 3. program-set exit status
  r = await AdaWasm.run(
    'with HAT; use HAT;\nprocedure Ex is begin Set_Exit_Status (7); end Ex;',
  );
  assert.strictEqual(r.exitCode, 7);

  // 4. compile error -> diagnostics on stderr, exit 1
  r = await AdaWasm.run('with HAT; procedure Bad is begin Put_Line (; end Bad;');
  assert.strictEqual(r.exitCode, 1);
  assert.ok(r.stderr.length > 0, 'expected compiler diagnostics on stderr');
  assert.ok(r.diagnostics.length > 0);

  // 5. multiple files (with-ed package)
  r = await AdaWasm.run([
    { filename: 'main.adb', content: 'with Helper;\nprocedure Main is begin Helper.Greeting; end Main;' },
    { filename: 'helper.ads', content: 'package Helper is procedure Greeting; end Helper;' },
    {
      filename: 'helper.adb',
      content:
        'with HAT; use HAT;\npackage body Helper is procedure Greeting is begin Put_Line ("multi"); end Greeting; end Helper;',
    },
  ]);
  assert.strictEqual(r.stdout, 'multi\n');
  assert.strictEqual(r.exitCode, 0);

  // 6. object-map convenience + explicit runtime
  const runtime = await AdaWasm.createRuntime();
  await runtime.warmUp();
  r = await runtime.run({ 'Foo.adb': 'with HAT; use HAT;\nprocedure Foo is begin Put_Line ("map"); end Foo;' });
  assert.strictEqual(r.stdout, 'map\n');

  // 7. isolated runs (a stale with-ed unit must not leak between runs)
  r = await AdaWasm.run('with HAT; use HAT;\nprocedure Solo is begin Put_Line ("solo"); end Solo;');
  assert.strictEqual(r.stdout, 'solo\n');

  // 8. repeated runs that read stdin (regression: libc keeps the stdin EOF flag
  // across runs, which made every run after the first fail with End_Error)
  const stdinProgram =
    'with HAT; use HAT;\nprocedure Twice is N : Integer; begin Get (N); Put_Line (N * 2); end Twice;';
  r = await AdaWasm.run(stdinProgram, '21');
  assert.strictEqual(r.stdout.trim(), '42');
  assert.strictEqual(r.exitCode, 0);
  r = await AdaWasm.run(stdinProgram, '5');
  assert.strictEqual(r.stdout.trim(), '10');
  assert.strictEqual(r.exitCode, 0);

  // 9. an unhandled runtime exception is reported, not thrown as a wasm exception
  r = await AdaWasm.run(
    'with HAT; use HAT;\nprocedure NoInput is N : Integer; begin Get (N); end NoInput;',
    '',
  );
  assert.strictEqual(r.exitCode, 1);
  assert.match(r.stderr, /END_ERROR/);

  console.log('all ada-wasm tests passed');
})().catch((e) => {
  console.error(e);
  process.exit(1);
});
