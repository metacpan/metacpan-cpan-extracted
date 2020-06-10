use 5.008004;
use Test2::V0 -no_srand => 1;
use Wasm::Wasmtime::FuncType;

is(
  Wasm::Wasmtime::FuncType->new([] => []),
  object {
    call [ isa => 'Wasm::Wasmtime::FuncType' ] => T();
    call_list params => [];
    call_list results => [];
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

    call to_string => "(param i32 f64) (result i64 f32)";

    call is_functype   => T();
    call is_globaltype => F();
    call is_tabletype  => F();
    call is_memorytype => F();
    call kind          => 'functype';
  },
  '(i32,f64)->(i64,f32)',
);

done_testing;
