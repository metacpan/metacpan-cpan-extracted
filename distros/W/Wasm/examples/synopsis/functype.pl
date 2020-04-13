use strict;
use warnings;
use Wasm::Wasmtime;

my $functype = Wasm::Wasmtime::FuncType->new(
  # This function type takes a 32 bit and 64 bit
  # integer and returns a double floating point
  [ 'i32', 'i64' ] => [ 'f64' ],
);
