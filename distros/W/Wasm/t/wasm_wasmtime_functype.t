use Test2::V0 -no_srand => 1;
use Wasm::Wasmtime::FuncType;

is(
  Wasm::Wasmtime::FuncType->new([] => []),
  object {
    call [ isa => 'Wasm::Wasmtime::FuncType' ] => T();
    call_list params => [];
    call_list results => [];
    call as_externtype => object {
      call [ isa => 'Wasm::Wasmtime::ExternType' ] => T();
    };
  },
  'functype with no args or return type',
);

is(
  Wasm::Wasmtime::FuncType->new(['i32','f64'] => ['i64','f32']),
  object {
    call [ isa => 'Wasm::Wasmtime::FuncType' ] => T();
    call_list params => array {
      item object {
        call [ isa => 'Wasm::Wasmtime::ValType' ] => T();
        call kind => 'i32';
      };
      item object {
        call [ isa => 'Wasm::Wasmtime::ValType' ] => T();
        call kind => 'f64';
      };
      end;
    };
    call_list results => array {
      item object {
        call [ isa => 'Wasm::Wasmtime::ValType' ] => T();
        call kind => 'i64';
      };
      item object {
        call [ isa => 'Wasm::Wasmtime::ValType' ] => T();
        call kind => 'f32';
      };
      end;
    };
    call as_externtype => object {
      call [ isa => 'Wasm::Wasmtime::ExternType' ] => T();
    };
  },
  '(i32,f64)->(i64,f32)',
);

done_testing;
