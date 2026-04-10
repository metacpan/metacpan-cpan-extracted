use 5.008003;
use strict;
use warnings;
use lib 'lib';
use Test2::Bundle::Numerical qw(:all);

plan(3);
my $tol = relative_tolerance(4);
float_is(1.0, 1.0, 'float_is accepts identical values');
float_is(1.0, 1.0 + $tol, 'float_is accepts close relative values', {method => 'relative', ulps => 4});
float_is(1.0, 1.0 + 1e-9, 'float_is accepts close absolute values', {method => 'absolute', tolerance => 1e-8});
