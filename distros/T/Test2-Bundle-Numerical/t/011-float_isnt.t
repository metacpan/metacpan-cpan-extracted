use 5.008003;
use strict;
use warnings;
use lib 'lib';
use Test2::Bundle::Numerical qw(:all);

plan(3);
float_isnt(1.0, 2.0, 'float_isnt accepts different values');
float_isnt(0.0, 1e-3, 'float_isnt accepts another distinct pair');
float_isnt(1.0, 1.1, 'float_isnt accepts values that are clearly different');
