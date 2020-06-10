use 5.008004;
use Test2::V0 -no_srand => 1;
use Test2::Plugin::Wasm;
use lib 't/lib';
use Test2::Tools::Wasm;
use Wasm::Wasmtime::Extern;

is(
  wasm_instance_ok([], q{
    (module
      (func (export "foo") (param i32 i32) (result i32)
        local.get 0
        local.get 1
        i32.add)
      (memory (export "bar") 2 3)
      (table (export "frooble") 1 funcref)
      (global (export "hi") (mut i32) (i32.const 1))
    )
  }),
  object {
    call exports => object {
      call foo => object {
        call [ isa => 'Wasm::Wasmtime::Func' ] => T();
        call type => object {
          call [ isa => 'Wasm::Wasmtime::FuncType' ] => T();
        };
        call kind      => 'func';
      };
      call hi => object {
        call [ isa => 'Wasm::Wasmtime::Global' ] => T();
        call type => object {
          call [ isa => 'Wasm::Wasmtime::GlobalType' ] => T();
        };
        call kind      => 'global';
      };
      call frooble => object {
        call [ isa => 'Wasm::Wasmtime::Table' ] => T();
        call type => object {
          call [ isa => 'Wasm::Wasmtime::TableType' ] => T();
        };
        call kind      => 'table';
      };
      call bar => object {
        call [ isa => 'Wasm::Wasmtime::Memory' ] => T();
        call type => object {
          call [ isa => 'Wasm::Wasmtime::MemoryType' ] => T();
        };
        call kind      => 'memory';
      };
    };
  },
  'exter objects',
);

done_testing;
