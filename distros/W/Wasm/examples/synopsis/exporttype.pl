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

my($foo, $bar) = $module->exports;

print $foo->name, "\n";        # foo
print $foo->type->kind, "\n";  # func
print $bar->name, "\n";        # bar
print $bar->type->kind, "\n";  # memory
