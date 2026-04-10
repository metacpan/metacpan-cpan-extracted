use 5.008003;
use strict;
use warnings;
use lib 'lib';
use Test2::Bundle::Numerical qw(:all);

plan(3);
within_tol(1.0, 1.0 + 1e-9, 'within_tol alias accepts nearby values', 1e-8);
within_tol(1.0, 1.0, 'within_tol accepts identical values', 1e-8);
within_tol(0.0, 1e-9, 'within_tol accepts a small absolute value', 1e-8);
