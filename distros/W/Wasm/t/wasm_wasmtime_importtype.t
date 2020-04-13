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
    call_list imports => array {
      item object {
        call [ isa => 'Wasm::Wasmtime::ImportType' ] => T();
        call name => 'hello';
        call type => object {
          call [ isa => 'Wasm::Wasmtime::ExternType' ] => T();
        };
        call module => 'xx';
      };
      end;
    };
  },
  'import types are good'
);

done_testing;
