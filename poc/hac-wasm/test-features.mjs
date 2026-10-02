import createHacModule from './hac.js';

const out = [];
const err = [];

function makeStdin(text) {
  const bytes = Array.from(new TextEncoder().encode(text));
  let i = 0;
  return () => (i < bytes.length ? bytes[i++] : null); // null = EOF
}

const Module = await createHacModule({
  print: (s) => out.push(s),
  printErr: (s) => err.push(s),
  stdin: makeStdin('hello from stdin\n'),
});
Module._main();

function run(source) {
  const name = (source.match(/\bprocedure\s+([A-Za-z]\w*)/i) || [, 'main'])[1];
  Module.FS.writeFile(`/${name}.adb`, source);
  Module.ccall('hac_run', null, ['string'], [`${name}.adb`]);
}

console.log('--- stdin test ---');
run(`with HAT; use HAT;
procedure Echo is
  V : VString;
begin
  Get_Line (V);
  Put_Line ("echo: " & V);
end Echo;`);

console.log('--- multi-file test ---');
Module.FS.writeFile('/helper.ads', `package Helper is
  procedure Greeting;
end Helper;`);
Module.FS.writeFile('/helper.adb', `with HAT; use HAT;
package body Helper is
  procedure Greeting is
  begin
    Put_Line ("hello from helper");
  end Greeting;
end Helper;`);
run(`with Helper;
procedure Main is
begin
  Helper.Greeting;
end Main;`);

console.log('--- output ---');
console.log(out.join('\n'));
if (err.length) console.log('--- errors ---\n' + err.join('\n'));
