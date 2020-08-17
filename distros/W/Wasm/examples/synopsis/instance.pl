use strict;
use warnings;
use Wasm::Wasmtime;

my $store = Wasm::Wasmtime::Store->new;
my $module = Wasm::Wasmtime::Module->new($store->engine, wat => '(module)');
my $instance = Wasm::Wasmtime::Instance->new($module, $store, []);
