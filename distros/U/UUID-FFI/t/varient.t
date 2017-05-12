use strict;
use warnings;
use Test::More tests => 1;
use UUID::FFI;

my $uuid = UUID::FFI->new_random;
like $uuid->variant, qr{^(ncs|dce|microsoft|other)$}, 'variant';
note $uuid->variant;
