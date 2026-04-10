use 5.008003;
use strict;
use warnings;
use lib 'lib';
use Test2::Bundle::Numerical qw(:all);

plan(3);
like(bits_diff(1.0, 2.0), qr/ vs /, 'bits_diff formats a comparison string');
ok(length(bits_diff(1.0, 2.0)) > 0, 'bits_diff returns a nonempty string');
like(bits_diff(-1.0, 1.0), qr/ vs /, 'bits_diff contains a separator for distinct values');
