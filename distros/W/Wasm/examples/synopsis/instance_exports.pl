use strict;
use warnings;
use Wasm::Wasmtime;

my $store = Wasm::Wasmtime::Store->new;
my $module = Wasm::Wasmtime::Module->new( $store, wat => q{
  (module
   (func (export "add") (param i32 i32) (result i32)
     local.get 0
     local.get 1
     i32.add)
  )
});

my $instance = Wasm::Wasmtime::Instance->new($module, $store);

my $exports = $instance->exports;

print $exports->add->call(1,2),   "\n";  # 3
print $exports->{add}->call(1,2), "\n";  # 3
print $exports->[0]->call(1,2),   "\n";  # 3
