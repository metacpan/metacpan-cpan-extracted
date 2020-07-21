use 5.008004;
use Test2::V0 -no_srand => 1;
use Test2::Plugin::Wasm;
use Wasm::Wasmtime::Caller;

imported_ok 'wasmtime_caller';
is(wasmtime_caller(), U());

{
  require Wasm::Wasmtime;
  my $store = Wasm::Wasmtime::Store->new;
  my $module = Wasm::Wasmtime::Module->new( $store, wat => q{
    (module
      (func $hello (import "" "hello"))
      (func (export "run") (call $hello))
      (memory (export "memory") 2 3)
    )
  });

  my $caller;
  my $memory;
  my $hello = Wasm::Wasmtime::Func->new(
    $store,
    Wasm::Wasmtime::FuncType->new([],[]),
    sub {
      $caller = wasmtime_caller;
      $memory = $caller->export_get('memory');
      note "hello world!\n"
    },
  );

  my $instance = Wasm::Wasmtime::Instance->new($module, $store, [$hello]);
  $instance->exports->run->call(); # hello world!

  isa_ok $caller, 'Wasm::Wasmtime::Caller';
  isa_ok $memory, 'Wasm::Wasmtime::Memory';
  is $caller->export_get('memory'), U();
}

done_testing;
