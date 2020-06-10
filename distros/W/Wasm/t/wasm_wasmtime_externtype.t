use 5.008004;
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
    call exports => object {
      call foo => object {
        call [ isa => 'Wasm::Wasmtime::FuncType' ] => T();
        call kind => 'functype';
        call is_functype   => T();
        call is_globaltype => F();
        call is_tabletype  => F();
        call is_memorytype => F();
      };
      call baz => object {
        call [ isa => 'Wasm::Wasmtime::GlobalType' ] => T();
        call kind => 'globaltype';
        call is_functype   => F();
        call is_globaltype => T();
        call is_tabletype  => F();
        call is_memorytype => F();
        call content => object {
          call [ isa => 'Wasm::Wasmtime::ValType' ] => T();
          call kind => 'i32';
        };
        call mutability => 'var';
      };
      call frooble => object {
        call [ isa => 'Wasm::Wasmtime::TableType' ] => T();
        call kind => 'tabletype';
        call is_functype   => F();
        call is_globaltype => F();
        call is_tabletype  => T();
        call is_memorytype => F();
        call element => object {
          call [ isa => 'Wasm::Wasmtime::ValType' ] => T();
          call kind => 'funcref';
        };
        call limits => [ 1, 3 ];
      };
      call bar => object {
        call [ isa => 'Wasm::Wasmtime::MemoryType' ] => T();
        call kind => 'memorytype';
        call is_functype   => F();
        call is_globaltype => F();
        call is_tabletype  => F();
        call is_memorytype => T();
      };
    };
  },
  'test extern types'
);

done_testing;
