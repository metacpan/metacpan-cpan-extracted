use strict;
use warnings;
use Wasm::Trap;

my $trap = Wasm::Trap->new(
  "something went bump in the night\0",
);
