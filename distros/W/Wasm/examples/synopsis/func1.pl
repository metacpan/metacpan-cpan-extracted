use strict;
use warnings;

# Call a wasm function from Perl
use Wasm::Wasmtime;

my $module = Wasm::Wasmtime::Module->new( wat => q{
  (module
   (func (export "add") (param i32 i32) (result i32)
     local.get 0
     local.get 1
     i32.add)
  )
});

my $instance = Wasm::Wasmtime::Instance->new($module);
my $add = $instance->get_export('add')->as_func;
print $add->call(1,2), "\n";  # 3
