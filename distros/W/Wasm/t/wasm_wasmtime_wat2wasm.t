use Test2::V0 -no_srand => 1;
use Wasm::Wasmtime::Wat2Wasm;

imported_ok 'wat2wasm';

is(
  wat2wasm('(module)'),
  D(),
  'okay with good module',
);

is(
  dies { wat2wasm('f00f') },
  match qr/wat2wasm error/,
  'dies with bad input',
);

done_testing;
