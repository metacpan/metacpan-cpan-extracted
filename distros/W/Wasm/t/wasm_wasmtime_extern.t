use Test2::V0 -no_srand => 1;
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
    )
  }),
  object {
    call [ get_export => 'foo' ] => object{
      call [ isa => 'Wasm::Wasmtime::Extern' ] => T();
      call type => object {
        call [ isa => 'Wasm::Wasmtime::ExternType' ] => T();
      };
      call kind      => 'func';
      call kind_num  => match qr/^[0-9]+$/;
      call as_func   => object {
        call [ isa => 'Wasm::Wasmtime::Func' ] => T();
      };
      call as_memory => U();
    };
    call [ get_export => 'bar' ] => object{
      call [ isa => 'Wasm::Wasmtime::Extern' ] => T();
      call type => object {
        call [ isa => 'Wasm::Wasmtime::ExternType' ] => T();
      };
      call kind      => 'memory';
      call kind_num  => match qr/^[0-9]+$/;
      call as_func   => U();
      call as_memory => object {
        call [ isa => 'Wasm::Wasmtime::Memory' ] => T();
      };
    };
  },
  'exter objects',
);

done_testing;
