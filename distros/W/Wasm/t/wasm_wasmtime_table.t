use Test2::V0 -no_srand => 1;
use lib 't/lib';
use Test2::Tools::Wasm;
use Wasm::Wasmtime::Table;

is(
  wasm_instance_ok([], q{
    (module (table (export "frooble") 1 funcref))
  }),
  object {
    call [ get_export => 'frooble' ] => object {
      call as_table => object {
        call [ isa => 'Wasm::Wasmtime::Table' ] => T();
        call type => object {
          call [ isa => 'Wasm::Wasmtime::TableType' ] => T();
        };
        call size => 1;
      };
    };
  },
  'table good'
);

done_testing;
