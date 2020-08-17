use strict;
use warnings;
use Wasm::Wasmtime;

my $store = Wasm::Wasmtime::Store->new;
my $instance = Wasm::Wasmtime::Instance->new(
  Wasm::Wasmtime::Module->new($store->engine, wat => q{
    (module
      (func (export "foo") (param i32 i32) (result i32)
        local.get 0
        local.get 1
        i32.add)
      (memory (export "bar") 2 3)
    )
  }),
  $store,
);

my $foo = $instance->exports->foo;
print $foo->kind, "\n";  # func

my $bar = $instance->exports->bar;
print $bar->kind, "\n";  # memory
