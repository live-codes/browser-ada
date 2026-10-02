import createHacModule from './hac.js';

const out = [], err = [];
const Module = await createHacModule({ print: (s) => out.push(s), printErr: (s) => err.push(s) });
Module._main();

function run(source, name) {
  name = name || (source.match(/\bprocedure\s+([A-Za-z]\w*)/i) || [, 'main'])[1];
  Module.FS.writeFile(`/${name}.adb`, source);
  return Module.ccall('hac_run', 'number', ['string'], [`${name}.adb`]);
}

const ok = run(`with HAT; use HAT;
procedure Ok is begin Put_Line ("fine"); end Ok;`);

const custom = run(`with HAT; use HAT;
procedure Ex is begin Set_Exit_Status (42); end Ex;`);

const broken = run(`with HAT; procedure Bad is begin Put_Line (; end Bad;`);

console.log('exit codes:', { ok, custom, broken });
console.log('stdout:', JSON.stringify(out));
console.log('stderr:', JSON.stringify(err));
