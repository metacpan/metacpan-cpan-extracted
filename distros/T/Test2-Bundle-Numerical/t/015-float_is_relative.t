use 5.008003;
use strict;
use warnings;
use lib 'lib';
use Test2::Bundle::Numerical qw(:all);

plan(3);
my $tol = relative_tolerance(4);
float_is_relative(1.0, 1.0 + $tol, 'float_is_relative accepts close values', 4);
float_is_relative(1000.0, 1000.0 + $tol * 1000 * 0.9, 'float_is_relative accepts large magnitude values', 4);
float_is_relative(0.1, 0.1 + $tol * 0.1, 'float_is_relative accepts small magnitude values', 4);
