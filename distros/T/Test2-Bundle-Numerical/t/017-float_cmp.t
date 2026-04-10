use 5.008003;
use strict;
use warnings;
use lib 'lib';
use Test2::Bundle::Numerical qw(:all);

plan(3);
is(float_cmp(1.0, 2.0), -1, 'float_cmp orders smaller before larger');
is(float_cmp(2.0, 1.0), 1, 'float_cmp orders larger after smaller');
is(float_cmp(1.0, 1.0), 0, 'float_cmp returns 0 for equal values');
