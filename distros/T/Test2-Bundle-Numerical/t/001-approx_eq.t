use 5.008003;
use strict;
use warnings;
use lib 'lib';
use Test2::Bundle::Numerical qw(:all);

plan(3);
approx_eq(1.0, 1.0, 1e-12, 'approx_eq returns true for identical values');
approx_eq(1.0, 1.0 + 0.5e-12, 1e-12, 'approx_eq returns true for small delta');
approx_eq(0.0, 1e-13, 1e-12, 'approx_eq accepts a small absolute value');
