use strict;
use warnings;
use Wasm::Wasmtime;

my $store = Wasm::Wasmtime::Store->new;
my $global = Wasm::Wasmtime::Global->new(
  $store,
  Wasm::Wasmtime::GlobalType->new('i32','var'),
  42,
);

print $global->get, "\n";  # 42
$global->set(99);
print $global->get, "\n";  # 99

