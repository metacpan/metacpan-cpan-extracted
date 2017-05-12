use strict;
use warnings;
use Test::More tests => 2;
use UUID::FFI;

my $uuid = UUID::FFI->new_random;
isa_ok $uuid, 'UUID::FFI';

is "$uuid", $uuid->as_hex, 'stringify';
note $uuid->as_hex;
