use 5.008004;
use Test2::V0 -no_srand => 1;
use Wasm::Wasmtime::Config;
use Wasm::Wasmtime::Engine;

is(
  Wasm::Wasmtime::Engine->new,
  object {
    call ['isa','Wasm::Wasmtime::Engine'] => T();
  },
  'default config',
);

is(
  Wasm::Wasmtime::Engine->new(Wasm::Wasmtime::Config->new),
  object {
    call ['isa','Wasm::Wasmtime::Engine'] => T();
  },
  'explicit config',
);

done_testing;
