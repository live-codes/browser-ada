import createHacModule from './hac.js';

const out = [];
const err = [];

const Module = await createHacModule({
  print: (s) => out.push(s),
  printErr: (s) => err.push(s),
});

// Elaborate HAC itself.
Module._main();

const program = `
with HAT;
procedure Hello is
begin
  HAT.Put_Line ("Hello from Ada, compiled and run in the browser!");
  for I in 1 .. 5 loop
    HAT.Put ("I squared = ");
    HAT.Put_Line (I * I);
  end loop;
end Hello;
`;

// HAC requires the file base name to match the main subprogram name.
const name = (program.match(/\bprocedure\s+([A-Za-z]\w*)/i) || [, 'main'])[1];
Module.FS.writeFile(`/${name}.adb`, program);

Module.ccall('hac_run', null, ['string'], [`${name}.adb`]);

console.log('--- program output ---');
console.log(out.join('\n'));
if (err.length) {
  console.log('--- diagnostics ---');
  console.log(err.join('\n'));
}
