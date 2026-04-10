use 5.008003;
use strict;
use warnings;
use lib 'lib';
use Test2::Bundle::Numerical qw(:all);

plan(3);
float_ne(1.0, 2.0, 'float_ne accepts different values');
float_ne(0.0, 1e-3, 'float_ne accepts another distinct pair');
float_ne(1.0, 1.1, 'float_ne accepts clearly different values');
