use 5.008004;
use Test2::V0 -no_srand => 1;
use Wasm::Wasmtime::Engine;
use Wasm::Wasmtime::Store;

is(
  Wasm::Wasmtime::Store->new,
  object {
    call ['isa','Wasm::Wasmtime::Store'] => T();
    call engine => object {
      call ['isa','Wasm::Wasmtime::Engine'] => T();
    };
    call_list 'gc' => [];
  },
  'default engine',
);

is(
  Wasm::Wasmtime::Store->new(Wasm::Wasmtime::Engine->new),
  object {
    call ['isa','Wasm::Wasmtime::Store'] => T();
    call engine => object {
      call ['isa','Wasm::Wasmtime::Engine'] => T();
    };
  },
  'explicit engine',
);

done_testing;
