use 5.008003;
use strict;
use warnings;
use lib 'lib';
use Test2::Bundle::Numerical qw(:all);

plan(3);
my $tol = relative_tolerance(4);
ulp_equal(1.0, 1.0 + $tol, 4, 'ulp_equal accepts a close value');
ulp_equal(2.0, 2.0 + $tol * 2, 4, 'ulp_equal accepts another close value');
ulp_equal(4.0, 4.0 + $tol * 4, 4, 'ulp_equal accepts a larger value');
