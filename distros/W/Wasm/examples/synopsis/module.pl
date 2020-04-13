use strict;
use warnings;
use Wasm::Wasmtime;

my $module = Wasm::Wasmtime::Module->new( wat => '(module)' );
