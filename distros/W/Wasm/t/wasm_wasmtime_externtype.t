use Test2::V0 -no_srand => 1;
use lib 't/lib';
use Test2::Tools::Wasm;
use Wasm::Wasmtime::ExternType;

is(
  wasm_module_ok(q{
    (module
      (func (export "foo") (param i32 i32) (result i32)
        local.get 0
        local.get 1
        i32.add)
      (memory (export "bar") 2 3)
      (global (export "baz") (mut i32) (i32.const 1))
      (table (export "frooble") 1 3 funcref)
    )
  }),
  object {
    call [ get_export => 'foo' ] => object {
      call [ isa => 'Wasm::Wasmtime::ExternType' ] => T();
      call kind => 'func';
      call kind_num => match qr/^[0-9]+$/;
      call as_functype => object {
        call [ isa => 'Wasm::Wasmtime::FuncType' ] => T();
      };
      call as_globaltype => U();
      call as_tabletype => U();
      call as_memorytype => U();
    };
    call [ get_export => 'bar' ] => object {
      call [ isa => 'Wasm::Wasmtime::ExternType' ] => T();
      call kind => 'memory';
      call kind_num => match qr/^[0-9]+$/;
      call as_functype => U();
      call as_globaltype => U();
      call as_tabletype => U();
      call as_memorytype => object {
        call [ isa => 'Wasm::Wasmtime::MemoryType' ] => T();
      };
    };
    call [ get_export => 'baz' ] => object {
      call [ isa => 'Wasm::Wasmtime::ExternType' ] => T();
      call kind => 'global';
      call kind_num => match qr/^[0-9]+$/;
      call as_functype => U();
      call as_globaltype => object {
        call [ isa => 'Wasm::Wasmtime::GlobalType' ] => T();
        call content => object {
          call [ isa => 'Wasm::Wasmtime::ValType' ] => T();
          call kind => 'i32';
        };
        call mutability => 'var';
      };
      call as_tabletype => U();
      call as_memorytype => U();
    };
    call [ get_export => 'frooble' ] => object {
      call [ isa => 'Wasm::Wasmtime::ExternType' ] => T();
      call kind => 'table';
      call kind_num => match qr/^[0-9]+$/;
      call as_functype => U();
      call as_globaltype => U();
      call as_tabletype => object {
        call [ isa => 'Wasm::Wasmtime::TableType' ] => T();
        call element => object {
          call [ isa => 'Wasm::Wasmtime::ValType' ] => T();
          call kind => 'funcref';
        };
        call limits => [ 1, 3 ];
      };
      call as_memorytype => U();
    };
  },
  'test extern types'
);

done_testing;
