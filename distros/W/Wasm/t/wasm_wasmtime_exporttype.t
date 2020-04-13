use Test2::V0 -no_srand => 1;
use lib 't/lib';
use Test2::Tools::Wasm;
use Wasm::Wasmtime::ExportType;

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
    call_list exports => array {
      item object {
        call [ isa => 'Wasm::Wasmtime::ExportType' ] => T();
        call name => 'foo';
        call type => object {
          call [ isa => 'Wasm::Wasmtime::ExternType' ] => T();
        };
      };
      item object {
        call [ isa => 'Wasm::Wasmtime::ExportType' ] => T();
        call name => 'bar';
        call type => object {
          call [ isa => 'Wasm::Wasmtime::ExternType' ] => T();
        };
      };
      end;
    };
  },
  'export types okay',
);

done_testing;
