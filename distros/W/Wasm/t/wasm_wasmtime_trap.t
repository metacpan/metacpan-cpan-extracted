use 5.008004;
use Test2::V0 -no_srand => 1;
use Wasm::Wasmtime::Store;
use Wasm::Wasmtime::Trap;

is(
  Wasm::Wasmtime::Trap->new(Wasm::Wasmtime::Store->new, "foo\0"),
  object {
    call [isa => 'Wasm::Wasmtime::Trap'] => T();
    call message => 'foo';
    call sub { my $trap = shift; "$trap" } => "foo\n";
    call exit_status => undef;
  },
  'created trap ok',
);

{
  require Wasm::Wasmtime;
  my $store = Wasm::Wasmtime::Store->new;
  my $linker = Wasm::Wasmtime::Linker->new($store);

  my $wasi = Wasm::Wasmtime::WasiInstance->new(
    $store,
    "wasi_snapshot_preview1",
    Wasm::Wasmtime::WasiConfig->new,
  );
  $linker->define_wasi($wasi);
  my $module = Wasm::Wasmtime::Module->new($store->engine, wat => q{
    (module
      (import "wasi_snapshot_preview1" "proc_exit" (func $proc_exit (param i32)))
      (memory 10)
      (export "memory" (memory 0))
      (func $main
        (call $proc_exit (i32.const 7))
      )
      (start $main)
    )
  });
  is(
    dies { $linker->instantiate($module) },
    object {
      call [ isa => 'Wasm::Wasmtime::Trap' ] => T();
      call exit_status => 7;
    },
  );
}

done_testing;
