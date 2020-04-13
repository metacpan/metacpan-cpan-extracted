use strict;
use warnings;
use Wasm::Wasmtime;
use PeekPoke::FFI qw( poke );

my $store = Wasm::Wasmtime::Store->new;

# create a new memory object with a minumum
# of 3 pages and maximum of 9
my $memory = Wasm::Wasmtime::Memory->new(
  $store,
  Wasm::Wasmtime::MemoryType->new([3,9]),
);

poke($memory->data + 10, 42);                   # store the byte 42 at offset
                                                # 10 inside the data region

printf "data_size = %x\n", $memory->data_size;  # 30000
printf "size      = %d\n", $memory->size;       # 3

$memory->grow(4);                               # increase data region by 4 pages

printf "data_size = %x\n", $memory->data_size;  # 70000
printf "size      = %d\n", $memory->size;       # 7
