use 5.008003;
use strict;
use warnings;
use lib 'lib';
use Test2::Bundle::Numerical qw(:all);

plan 4;

is_lt(1, 2, '1 is less than 2');
is_lte(2, 2, '2 is less than or equal to 2');
is_gt(3, 2, '3 is greater than 2');
is_gte(2, 2, '2 is greater than or equal to 2');
