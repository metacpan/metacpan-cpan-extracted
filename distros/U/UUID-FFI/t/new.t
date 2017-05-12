use strict;
use warnings;
use Test::More tests => 3;
use UUID::FFI;

my $uuid = UUID::FFI->new('267a6045-e470-49fc-b9c8-9e20d39892e0');
isa_ok $uuid, 'UUID::FFI';

is $uuid->as_hex, '267a6045-e470-49fc-b9c8-9e20d39892e0', 'uuid.as_hex';
note $uuid->as_hex;

eval { UUID::FFI->new('foo') };
isnt $@, '', 'bad hex';
note $@;
