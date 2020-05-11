use strict;
use warnings;
use Wasm::Wasmtime;

my $module = Wasm::Wasmtime::Module->new( wat => q{
  (module
   (func (export "add") (param i32 i32) (result i32)
     local.get 0
     local.get 1
     i32.add)
  )
});

my $exports = $module->exports;   # Wasm::Wasmtime::Module::Exports

my $type1      = $exports->add;   # this is the Wasm::Wasmtime::FuncType for add
my $type2      = $exports->{add}; # this is also the Wasm::Wasmtime::FuncType for add
my $exporttype = $exports->[0];   # this is the Wasm::Wasmtime::ExportType for add
