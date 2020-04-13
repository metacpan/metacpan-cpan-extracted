use Test2::V0 -no_srand => 1;
use Wasm::Wasmtime::TableType;

is(
  Wasm::Wasmtime::TableType->new('i32',[3,4]),
  object {
    call [ isa => 'Wasm::Wasmtime::TableType' ] => T();
    call element => object {
      call [ isa => 'Wasm::Wasmtime::ValType' ] => T();
      call kind => 'i32';
    };
    call limits => [3,4];
    call as_externtype => object {
      call [ isa => 'Wasm::Wasmtime::ExternType' ] => T();
    }
  },
  'i32,const',
);

is(
  Wasm::Wasmtime::TableType->new('i64',[9,undef]),
  object {
    call [ isa => 'Wasm::Wasmtime::TableType' ] => T();
    call element => object {
      call [ isa => 'Wasm::Wasmtime::ValType' ] => T();
      call kind => 'i64';
    };
    call limits => [9,0xffffffff];
    call as_externtype => object {
      call [ isa => 'Wasm::Wasmtime::ExternType' ] => T();
    }
  },
  'i64,var',
);

is(
  Wasm::Wasmtime::TableType->new(Wasm::Wasmtime::ValType->new('f32'),[1,6]),
  object {
    call [ isa => 'Wasm::Wasmtime::TableType' ] => T();
    call element => object {
      call [ isa => 'Wasm::Wasmtime::ValType' ] => T();
      call kind => 'f32';
    };
    call limits => [1,6];
    call as_externtype => object {
      call [ isa => 'Wasm::Wasmtime::ExternType' ] => T();
    }
  },
  '(i64),var',
);

done_testing;
