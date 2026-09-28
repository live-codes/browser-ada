// Verify the single-file (classic script) build the same way a browser would:
// eval the script, then use the global createHacModule factory.
const fs = require('fs');
const path = require('path');

const code = fs.readFileSync(path.join(__dirname, 'hac-standalone.js'), 'utf8');
eval(code);

(async () => {
  const out = [];
  const err = [];
  const Module = await createHacModule({
    print: (s) => out.push(s),
    printErr: (s) => err.push(s),
  });
  Module._main();

  const src = `with HAT;
procedure Hi is
begin
  HAT.Put_Line ("standalone build works");
  HAT.Put_Line (6 * 7);
end Hi;`;
  Module.FS.writeFile('/hi.adb', src);
  Module.ccall('hac_run', null, ['string'], ['hi.adb']);

  console.log('--- output ---');
  console.log(out.join('\n'));
  if (err.length) console.log('--- errors ---\n' + err.join('\n'));
})();
