use 5.008003;
use strict;
use warnings;
use lib 'lib';
use Test2::Bundle::Numerical qw(:all);

plan(3);
like(bits_hex(1.0), qr/^[0-9a-f]+$/, 'bits_hex returns a hex string');
ok(length(bits_hex(1.0)) % 2 == 0, 'bits_hex length is even');
ok(bits_hex(1.0) ne bits_hex(2.0), 'bits_hex differs for different values');
