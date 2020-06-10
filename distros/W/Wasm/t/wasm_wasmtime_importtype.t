use 5.008004;
use Test2::V0 -no_srand => 1;
use lib 't/lib';
use Test2::Tools::Wasm;
use Wasm::Wasmtime::ImportType;

is(
  wasm_module_ok(q{
    (module
      (func $hello (import "xx" "hello"))
    )
  }),
  object {
    call_list sub { @{ shift->imports } } => array {
      item object {
        call [ isa => 'Wasm::Wasmtime::ImportType' ] => T();
        call name => 'hello';
        call type => object {
          call [ isa => 'Wasm::Wasmtime::FuncType' ] => T();
        };
        call module => 'xx';
        call to_string => '(func (import "xx" "hello") )';
      };
      end;
    };
  },
  'import types are good'
);

is(
  wasm_module_ok(q{
    (module
      (func $hello (import "xx" "hello") (param i32 i32 i32) (result f32))
    )
  }),
  object {
    call_list sub { @{ shift->imports } } => array {
      item object {
        call [ isa => 'Wasm::Wasmtime::ImportType' ] => T();
        call name => 'hello';
        call type => object {
          call [ isa => 'Wasm::Wasmtime::FuncType' ] => T();
        };
        call module => 'xx';
        call to_string => '(func (import "xx" "hello") (param i32 i32 i32) (result f32))';
      };
      end;
    };
  },
  'import with function arguments'
);

done_testing;
