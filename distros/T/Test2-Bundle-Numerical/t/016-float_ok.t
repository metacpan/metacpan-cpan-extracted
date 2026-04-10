use 5.008003;
use strict;
use warnings;
use lib 'lib';
use Test2::Bundle::Numerical qw(:all);

plan(3);
my $tol = relative_tolerance(4);
float_ok(1.0, 1.0, 'float_ok accepts exact match');
float_ok(1.0, 1.0 + $tol, 'float_ok accepts close values', 4);
float_ok(100.0, 100.0 + $tol * 100 * 0.9, 'float_ok accepts close large values', 4);
