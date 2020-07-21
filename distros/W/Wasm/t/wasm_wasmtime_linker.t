use 5.008004;
use Test2::V0 -no_srand => 1;
use Test2::Plugin::Wasm;
use lib 't/lib';
use Test2::Tools::Wasm;
use Wasm::Wasmtime::Linker;
use Wasm::Wasmtime::WasiInstance;

my $instance = wasm_instance_ok( [], q{
  (module
    (func (export "add") (param i32 i32) (result i32)
      local.get 0
      local.get 1
      i32.add)
    (func (export "sub") (param i64 i64) (result i64)
      local.get 0
      local.get 1
      i64.sub)
    (memory (export "memory") 2 3)
  )
});

my $module = $instance->module;
my $store  = wasm_store();
my $wasi   = Wasm::Wasmtime::WasiInstance->new(
  $store, "wasi_snapshot_preview1",
);

my $instance2 = Wasm::Wasmtime::Instance->new(
  Wasm::Wasmtime::Module->new($store, wat => '(module)' ),
  $store,
);

my $module2 = Wasm::Wasmtime::Module->new($store, wat => '(module)' );

is(
  Wasm::Wasmtime::Linker->new(
    $store,
  ),
  object {
    call [ isa => 'Wasm::Wasmtime::Linker' ] => T();
    call [ allow_shadowing => 1 ] => D();
    call [ allow_shadowing => 0 ] => D();
    call [ define => 'xx', 'add0', $instance->exports->add ] => D();
    call [ define_wasi => $wasi ] => T();
    call [ define_instance => "foo", $instance2 ] => T();
    call [ instantiate => $module2 ] => object {
      call [ isa => 'Wasm::Wasmtime::Instance' ] => T();
    };
    call store => object {
      call [ isa => 'Wasm::Wasmtime::Store' ] => T();
    };

    call [ get_default => 'foo' ] => object {
      call [ isa => 'Wasm::Wasmtime::Func' ] => T();
      call call  => undef;
    };
  },
  'basics'
);

done_testing;
