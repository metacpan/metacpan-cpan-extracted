use strict;
use warnings;
use PeekPoke::FFI qw( peek poke );
use Wasm
  -api => 0,
  -wat => q{
    (module
      (memory (export "memory") 3 9)
    )
  }
;

# $memory isa Wasm::Memory
poke($memory->address + 10, 42);                # store the byte 42 at offset
                                                # 10 inside the data region

my($current, $min, $max) = $memory->limits;
printf "size    = %x\n", $memory->size;         # 30000
printf "current = %d\n", $current;              # 3
printf "min     = %d\n", $min;                  # 3
printf "max     = %d\n", $max;                  # 9

$memory->grow(4);                               # increase data region by 4 pages

($current, $min, $max) = $memory->limits;
printf "size    = %x\n", $memory->size;         # 70000
printf "current = %d\n", $current;              # 7
printf "min     = %d\n", $min;                  # 3
printf "max     = %d\n", $max;                  # 9
