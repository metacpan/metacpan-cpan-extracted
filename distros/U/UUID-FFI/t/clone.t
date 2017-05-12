use strict;
use warnings;
use Test::More tests => 4;
use UUID::FFI;

my $uuid = UUID::FFI->new('267a6045-e470-49fc-b9c8-9e20d39892e0');
isa_ok $uuid, 'UUID::FFI';

my $clone = $uuid->clone;
isnt $$clone, $$uuid, 'Different actual objects';
is $clone->as_hex, $uuid->as_hex, 'as string matches';
is $uuid->compare($clone), 0, 'compare';
