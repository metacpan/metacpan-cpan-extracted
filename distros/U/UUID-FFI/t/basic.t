use strict;
use warnings;
use Test::More tests => 1;
use UUID::FFI;

my $uuid = UUID::FFI->new_random;
isa_ok $uuid, 'UUID::FFI';
