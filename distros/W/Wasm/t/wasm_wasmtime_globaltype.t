use 5.008004;
use Test2::V0 -no_srand => 1;
use Wasm::Wasmtime::GlobalType;

is(
  Wasm::Wasmtime::GlobalType->new('i32','const'),
  object {
    call [ isa => 'Wasm::Wasmtime::GlobalType' ] => T();
    call content => object {
      call [ isa => 'Wasm::Wasmtime::ValType' ] => T();
      call kind => 'i32';
    };
    call mutability => 'const';
    call to_string => "(const i32)";

    call is_functype   => F();
    call is_globaltype => T();
    call is_tabletype  => F();
    call is_memorytype => F();
    call kind          => 'globaltype';
  },
  'i32,const',
);

is(
  Wasm::Wasmtime::GlobalType->new('i64','var'),
  object {
    call [ isa => 'Wasm::Wasmtime::GlobalType' ] => T();
    call content => object {
      call [ isa => 'Wasm::Wasmtime::ValType' ] => T();
      call kind => 'i64';
    };
    call mutability => 'var';
    call to_string => "(var i64)";
  },
  'i64,var',
);

is(
  Wasm::Wasmtime::GlobalType->new(Wasm::Wasmtime::ValType->new('f32'),'var'),
  object {
    call [ isa => 'Wasm::Wasmtime::GlobalType' ] => T();
    call content => object {
      call [ isa => 'Wasm::Wasmtime::ValType' ] => T();
      call kind => 'f32';
    };
    call mutability => 'var';
    call to_string => "(var f32)";
  },
  '(i64),var',
);

done_testing;
