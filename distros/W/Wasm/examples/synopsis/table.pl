use strict;
use warnings;
use Wasm::Wasmtime;

my $store = Wasm::Wasmtime::Store->new;
my $instance = Wasm::Wasmtime::Instance->new(
  Wasm::Wasmtime::Module->new($store, wat => q{
    (module
      (table (export "table") 1 funcref)
    )
  }),
  $store,
);

my $table = $instance->exports->table;
print $table->type->element->kind, "\n";   # funcref
print $table->size, "\n";                  # 1
