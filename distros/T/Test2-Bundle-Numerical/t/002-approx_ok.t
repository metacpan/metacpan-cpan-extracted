use 5.008003;
use strict;
use warnings;
use lib 'lib';
use Test2::Bundle::Numerical qw(:all);

plan(3);
approx_ok(1.0, 1.0, 1e-12, 'approx_ok alias works for exact match');
approx_ok(1.0, 1.0 + 0.5e-12, 1e-12, 'approx_ok works for close values');
approx_ok(0.0, 1e-13, 1e-12, 'approx_ok accepts a small absolute value');
