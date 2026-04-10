use 5.008003;
use strict;
use warnings;
use lib 'lib';
use Test2::Bundle::Numerical qw(:all);

plan(2);

is_deeply([1, 2.0], [1.0, 2], 'is_deeply compares numeric arrays');
is_deeply({a => 1, b => [2, 3.0]}, {a => 1.0, b => [2.0, 3]}, 'is_deeply compares nested numeric structures');
