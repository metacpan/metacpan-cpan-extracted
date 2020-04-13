use Test2::V0 -no_srand => 1;
use lib 't/lib';
use Test2::Tools::Wasm;
use Wasm::Wasmtime::MemoryType;

is(
  wasm_module_ok(q{
    (module
      (memory (export "frooble") 2 6)
    )
  }),
  object {
    call [ get_export => 'frooble' ] => object {
      call as_memorytype => object {
        call [ isa => 'Wasm::Wasmtime::MemoryType' ] => T();
        call limits => [2,6];
        call as_externtype => object {
          call [ isa => 'Wasm::Wasmtime::ExternType' ] => T();
        };
      };
    };
  },
  'memorytype class basics',
);

is(
  Wasm::Wasmtime::MemoryType->new([2,3]),
  object {
    call [ isa => 'Wasm::Wasmtime::MemoryType' ] => T();
    call limits => [2,3];
    call as_externtype => object {
      call [ isa => 'Wasm::Wasmtime::ExternType' ] => T();
    };
  },
  'standalone',
);

done_testing;
