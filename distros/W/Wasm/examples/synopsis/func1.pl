use strict;
use warnings;

# Call a wasm function from Perl
use Wasm::Wasmtime;

my $store = Wasm::Wasmtime::Store->new;
my $module = Wasm::Wasmtime::Module->new( $store->engine, wat => q{
  (module
   (func (export "add") (param i32 i32) (result i32)
     local.get 0
     local.get 1
     i32.add)
  )
});

my $instance = Wasm::Wasmtime::Instance->new($module, $store);
my $add = $instance->exports->add;
print $add->call(1,2), "\n";  # 3
