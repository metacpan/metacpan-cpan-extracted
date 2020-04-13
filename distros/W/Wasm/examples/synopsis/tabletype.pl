use strict;
use warnings;
use Wasm::Wasmtime;

my $tabletype = Wasm::Wasmtime::TableType->new('i32',[2,10]);
