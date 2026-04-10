use 5.008003;
use strict;
use warnings;
use lib 'lib';
use Test2::Bundle::Numerical qw(:all);

plan(3);
bits_ok(1.0, 1.0, 'bits_ok accepts identical floats');
bits_ok(0.0, 0.0, 'bits_ok accepts zero values');
bits_ok(-1.0, -1.0, 'bits_ok accepts identical negative values');
