use 5.008003;
use strict;
use warnings;
use lib 'lib';
use Test2::Bundle::Numerical qw(:all);

plan(3);
bits_equal(1.0, 1.0, 'bits_equal accepts identical floats');
bits_equal(0.0, 0.0, 'bits_equal accepts zero values');
ok(!bits_equal(1.0, 1.1, undef), 'bits_equal rejects different floats');
