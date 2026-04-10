use 5.008003;
use strict;
use warnings;
use lib 'lib';
use Test2::Bundle::Numerical qw(:all);

plan(3);
my $tol = relative_tolerance(4);
float_is_ulps(1.0, 1.0 + $tol, 'float_is_ulps accepts a ULP-close value', 4);
float_is_ulps(2.0, 2.0 + $tol * 2, 'float_is_ulps accepts another close value', 4);
float_is_ulps(4.0, 4.0 + $tol * 4, 'float_is_ulps accepts a slightly larger value', 4);
