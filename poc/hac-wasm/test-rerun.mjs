import createHacModule from './hac.js';

const out = [];
const err = [];
const Module = await createHacModule({
  print: (s) => out.push(s),
  printErr: (s) => err.push(s),
});
Module._main();

function run(source) {
  const name = (source.match(/\bprocedure\s+([A-Za-z]\w*)/i) || [, 'main'])[1];
  Module.FS.writeFile(`/${name}.adb`, source);
  Module.ccall('hac_run', null, ['string'], [`${name}.adb`]);
}

run(`with HAT; procedure One is begin HAT.Put_Line ("first run"); end One;`);
run(`with HAT; procedure Two is
       function Sq (X : Integer) return Integer is begin return X * X; end Sq;
     begin
       for I in 1 .. 3 loop HAT.Put_Line (Sq (I)); end loop;
     end Two;`);

console.log('--- output ---');
console.log(out.join('\n'));
if (err.length) console.log('--- errors ---\n' + err.join('\n'));
