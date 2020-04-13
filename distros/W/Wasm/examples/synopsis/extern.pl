use strict;
use warnings;
use Wasm::Wasmtime;

my $instance = Wasm::Wasmtime::Instance->new(
  Wasm::Wasmtime::Module->new(wat => q{
    (module
      (func (export "foo") (param i32 i32) (result i32)
        local.get 0
        local.get 1
        i32.add)
      (memory (export "bar") 2 3)
    )
  }),
);

my $externtype_foo = $instance->get_export('foo');
print $externtype_foo->kind, "\n";  # func

my $externtype_bar = $instance->get_export('bar');
print $externtype_bar->kind, "\n";  # memory
