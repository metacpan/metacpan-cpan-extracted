use strict;
use warnings;
use Wasm::Wasmtime;

my $instance = Wasm::Wasmtime::Instance->new(
  Wasm::Wasmtime::Module->new(wat => q{
    (module
      (table (export "table") 1 funcref)
    )
  }),
);

my $table = $instance->get_export('table')->as_table;
print $table->type->element->kind, "\n";   # funcref
print $table->size, "\n";                  # 1
