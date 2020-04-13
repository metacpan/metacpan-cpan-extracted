use strict;
use warnings;
use Wasm::Wasmtime;

my $module = Wasm::Wasmtime::Module->new(wat => '(module)');
my $instance = Wasm::Wasmtime::Instance->new($module, []);
