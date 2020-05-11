use Test2::V0 -no_srand => 1;
use Test2::Plugin::Wasm;
use lib 't/lib';
use Test2::Tools::Wasm;
use Wasm::Wasmtime::Module;
use Wasm::Wasmtime::Instance;

is(
  Wasm::Wasmtime::Instance->new(Wasm::Wasmtime::Module->new(wat => '(module)')),
  object {
    call [ isa => 'Wasm::Wasmtime::Instance' ] => T();
    call module => object {
      call [ isa => 'Wasm::Wasmtime::Module' ] => T();
    };
  },
  'created instance instance'
);

is(
  Wasm::Wasmtime::Instance->new(Wasm::Wasmtime::Module->new(wat => q{
    (module
      (func (export "add") (param i32 i32) (result i32)
        local.get 0
        local.get 1
        i32.add)
      (func (export "sub") (param i64 i64) (result i64)
        local.get 0
        local.get 1
        i64.sub)
      (memory (export "frooble") 2 3)
    )
  })),
  object {
    call [ isa => 'Wasm::Wasmtime::Instance' ] => T();
    call exports => object {
      call add => object {
        call [isa => 'Wasm::Wasmtime::Func'] => T();
      };
    };
    call_list sub { @{ shift->exports } } => array {
      item object {
        call [isa => 'Wasm::Wasmtime::Func'] => T();
        call type => object {
          call [isa => 'Wasm::Wasmtime::FuncType'] => T();
          call kind => 'functype';
          call_list params => array {
            item object { call kind => 'i32' };
            item object { call kind => 'i32' };
            end;
          };
        };
        call type => object {
          call [isa => 'Wasm::Wasmtime::FuncType'] => T();
        };
        call param_arity => 2;
        call result_arity => 1;
        call [call => 1, 2] => 3;
        call_list [call => 1, 2] => [3];
      };
      item object {
        call [isa => 'Wasm::Wasmtime::Func'] => T();
        call type => object {
          call [isa => 'Wasm::Wasmtime::FuncType'] => T();
          call kind => 'functype';
          call_list params => array {
            item object { call kind => 'i64' };
            item object { call kind => 'i64' };
            end;
          };
        };
        call type => object {
          call [isa => 'Wasm::Wasmtime::FuncType'] => T();
        };
        call param_arity => 2;
        call result_arity => 1;
        call [call => 3, 1] => 2;
        call_list [call => 3, 1] => [2];
      };
      item object {
        call [isa => 'Wasm::Wasmtime::Memory'] => T();
        call type => object {
          call [isa => 'Wasm::Wasmtime::MemoryType'] => T();
          call kind => 'memorytype';
        };
      };
      end;
    };
  },
  'created exports'
);

wasm_instance_ok [], '(module)';

is(
  dies {
    Wasm::Wasmtime::Instance->new(
      Wasm::Wasmtime::Module->new( wat => q{
        (module
          (func $hello (import "" "hello"))
          (func (export "run") (call $hello))
        )
      }),
    );
  },
  match qr/Got 0 imports, but expected 1/,
  'import count mismatch',
);

{
  my $it_works;

  my $store = Wasm::Wasmtime::Store->new;
  my $module = Wasm::Wasmtime::Module->new( $store, wat => q{
    (module
      (func $hello (import "" "hello"))
      (func (export "run") (call $hello))
    )
  });

  my $hello = Wasm::Wasmtime::Func->new(
    $store,
    Wasm::Wasmtime::FuncType->new([],[]),
    sub { $it_works = 1 },
  );

  my $instance = Wasm::Wasmtime::Instance->new($module, [$hello]);
  $instance->exports->run->();

  is $it_works, T(), 'callback called';
}

{
  my $it_works;

  is(
    wasm_instance_ok([sub { $it_works = 1 }], q{
      (module
        (func $hello (import "" "hello"))
        (func (export "run") (call $hello))
      )
    }),
    object {
      call exports => object {
        call run => object {
          call call => U();
        };
      };
    },
    'pass func as code ref'
  );

  is($it_works, T(), 'verified that we called the callback');
}

{
  wasm_instance_ok([undef], q{
    (module
      (import "" "" (memory 1))
    )
  });
}

{
  my $memory;
  wasm_instance_ok([\$memory], q{
    (module
      (import "" "" (memory 1))
    )
  });

  isa_ok $memory, 'Wasm::Wasmtime::Memory';
}

done_testing;
