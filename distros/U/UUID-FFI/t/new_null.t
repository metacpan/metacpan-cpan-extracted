use strict;
use warnings;
use Test::More tests => 3;
use UUID::FFI;

my $uuid = UUID::FFI->new_null;
isa_ok $uuid, 'UUID::FFI';

is $uuid->as_hex, '00000000-0000-0000-0000-000000000000', 'uuid.as_hex';
note $uuid->as_hex;

ok $uuid->is_null, 'is_null';
