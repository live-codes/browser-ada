import createAdaModule from './ada.js';

const Module = await createAdaModule();

// Elaborate the Ada program (calls __gnat_initialize + adainit).
Module._main();

console.log('ada_add(2, 3)      =', Module._ada_add(2, 3));
console.log('ada_fib(20)        =', Module._ada_fib(20));
console.log('ada_try_raise(1)   =', Module._ada_try_raise(1), '(expect 2: caught)');
console.log('ada_try_raise(0)   =', Module._ada_try_raise(0), '(expect 2: no raise)');
