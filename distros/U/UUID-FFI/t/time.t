use strict;
use warnings;
use Test::More tests => 1;
use UUID::FFI;

my $uuid = UUID::FFI->new('cf74dba4-64a5-11e4-9128-002522dfb514');
is $uuid->time, 1415162404, 'uuid.time';
