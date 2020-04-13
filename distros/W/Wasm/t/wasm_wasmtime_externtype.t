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
      call as_memorytype => U();
    }
  },
  'test extern types'
);

done_testing;
