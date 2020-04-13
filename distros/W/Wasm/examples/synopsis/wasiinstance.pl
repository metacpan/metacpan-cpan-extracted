use strict;
use warnings;
use Wasm::Wasmtime;

my $store = Wasm::Wasmtime::Store->new;
my $wasi  = Wasm::Wasmtime::WasiInstance->new(
  $store,
  "wasi_snapshot_preview1",
);
