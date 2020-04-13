use strict;
use warnings;
use Wasm::Wasmtime;

my $config = Wasm::Wasmtime::Config->new;
$config->wasm_multi_value(1);
my $engine = Wasm::Wasmtime::Engine->new($config);
