use Test2::V0 -no_srand => 1;
use Test2::Require::Module 'Test::Memory::Cycle';
use Test::Memory::Cycle;
use Wasm::Wasmtime;
use YAML qw( Dump );

skip_all 'not tested with ciperl:static' if defined $ENV{CIPSTATIC} && $ENV{CIPSTATIC} eq 'true';

subtest 'module' => sub {

  my $module = Wasm::Wasmtime::Module->new(
    wat => q{
      (module
        (func (export "add") (param i32 i32) (result i32)
         local.get 0
         local.get 1
         i32.add)
      )
    },
  );

  $module->imports;
  $module->exports;

  memory_cycle_ok $module;

  note Dump($module);
};


subtest 'instance' => sub {

  my $store = Wasm::Wasmtime::Store->new;
  my $instance = Wasm::Wasmtime::Instance->new(
    Wasm::Wasmtime::Module->new(
      $store->engine,
      wat => q{
        (module
          (func (export "add") (param i32 i32) (result i32)
           local.get 0
           local.get 1
           i32.add)
        )
      },
    ),
    $store,
    [],
  );

  $instance->exports;

  memory_cycle_ok $instance;

  note Dump($instance);
};

done_testing;
