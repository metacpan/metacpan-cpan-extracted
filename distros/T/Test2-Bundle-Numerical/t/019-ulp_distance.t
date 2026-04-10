use 5.008003;
use strict;
use warnings;
use lib 'lib';
use Test2::Bundle::Numerical qw(:all);

plan(3);
is(ulp_distance(1.0, 1.0), 0, 'ulp_distance is zero for identical values');
ok(ulp_distance(1.0, 1.0 + 1e-16) >= 0, 'ulp_distance returns non-negative values');
ok(ulp_distance(1.0, 2.0) > 0, 'ulp_distance is positive for different values');
