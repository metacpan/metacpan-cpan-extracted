use 5.008003;
use strict;
use warnings;
use lib 'lib';
use Test2::Bundle::Numerical qw(:all);

plan(5);

is(1, 1, 'is compares equal integers');
is(1.0, '1', 'is compares numeric values across types');
is(undef, undef, 'is compares undefined values correctly');
isnt(1, 2, 'isnt compares unequal values correctly');
is(100.000001 * 5, 500.000005, 'nope not correct');