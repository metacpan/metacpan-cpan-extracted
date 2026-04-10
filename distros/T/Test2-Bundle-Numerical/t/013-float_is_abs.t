use 5.008003;
use strict;
use warnings;
use lib 'lib';
use Test2::Bundle::Numerical qw(:all);

plan(3);
float_is_abs(1.0, 1.0 + 1e-9, 'float_is_abs accepts close values', 1e-8);
float_is_abs(0.0, 1e-9, 'float_is_abs accepts small absolute value', 1e-8);
float_is_abs(10.0, 10.0 + 1e-8, 'float_is_abs accepts a slightly different value', 1e-7);
