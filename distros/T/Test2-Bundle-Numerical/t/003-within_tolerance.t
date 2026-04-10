use 5.008003;
use strict;
use warnings;
use lib 'lib';
use Test2::Bundle::Numerical qw(:all);

plan(3);
within_tolerance(1.0, 1.0 + 1e-9, 'within_tolerance accepts nearby values', 1e-8);
within_tolerance(1.0, 1.0, 'within_tolerance accepts identical values', 1e-8);
within_tolerance(0.0, 1e-9, 'within_tolerance accepts a small absolute value', 1e-8);
