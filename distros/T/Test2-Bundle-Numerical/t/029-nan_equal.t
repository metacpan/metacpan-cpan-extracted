use 5.008003;
use strict;
use warnings;
use lib 'lib';
use Test2::Bundle::Numerical qw(:all);

plan(3);
nan_equal(0 + "nan", 0 + "nan", 'nan_equal accepts NaN comparison');
ok(!nan_equal(0 + "nan", 1.0, undef), 'nan_equal rejects NaN compared to number');
ok(!nan_equal(1.0, 2.0, undef), 'nan_equal rejects distinct normal numbers');
