use strict;
use warnings;
use Wasm::Wasmtime;

my $module = Wasm::Wasmtime::Module->new(wat => q{
  (module
    (func (export "foo") (param i32 i32) (result i32)
      local.get 0
      local.get 1
      i32.add)
    (memory (export "bar") 2 3)
  )
});

my $foo = $module->exports->foo;
print $foo->kind, "\n";  # functype

my $bar = $module->exports->bar;
print $bar->kind, "\n";  # memorytype
