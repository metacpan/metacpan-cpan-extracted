use strict;
use warnings;
use Wasm::Wasmtime;

# new memory type with minimum 3 and maximum 5 pages
my $memorytype = Wasm::Wasmtime::MemoryType->new([3,5]);
