use 5.008003;
use strict;
use warnings;
use lib 'lib';
use Test2::Bundle::Numerical qw(:all);

plan(3);
is(bits_compare(1.0, 1.0), 0, 'bits_compare returns zero for equal bits');
ok(bits_compare(1.0, 2.0) != 0, 'bits_compare distinguishes different values');
ok(bits_compare(2.0, 1.0) != 0, 'bits_compare distinguishes reversed values');
