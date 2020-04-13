use strict;
use warnings;
use Wasm::Wasmtime;

my $store = Wasm::Wasmtime::Store->new;
my $trap = Wasm::Wasmtime::Trap->new(
  $store,
  "something went bump in the night\0",
);
