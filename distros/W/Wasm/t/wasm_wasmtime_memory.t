use Test2::V0 -no_srand => 1;
use lib 't/lib';
use Test2::Tools::Wasm;
use Wasm::Wasmtime::Memory;
use Wasm::Wasmtime::Store;
use Wasm::Wasmtime::MemoryType;

is(
  wasm_instance_ok([], q{
    (module
      (memory (export "frooble") 2 6)
    )
  }),
  object {
    call [get_export => 'frooble'] => object {
      call [ isa => 'Wasm::Wasmtime::Extern' ] => T();
      call as_memory => object {
        call [ isa => 'Wasm::Wasmtime::Memory' ] => T();
        call type => object {
          call [ isa => 'Wasm::Wasmtime::MemoryType' ] => T();
        };
        call data => match qr/^[0-9]+$/;
        call data_size => match qr/^[0-9]+$/;
        call size => 2;
        call [ grow => 3] => T();
        call size => 5;
        call as_extern => object {
          call [ isa => 'Wasm::Wasmtime::Extern' ] => T();
        };
      };
    };
  },
  'memory class basics',
);

is(
  Wasm::Wasmtime::Memory->new(
    Wasm::Wasmtime::Store->new,
    Wasm::Wasmtime::MemoryType->new([1,2]),
  ),
  object {
    call [ isa => 'Wasm::Wasmtime::Memory' ] => T();
  },
  'standalone',
);

done_testing;
