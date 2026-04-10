use 5.008003;
use strict;
use warnings;
use lib 'lib';
use Test2::Bundle::Numerical qw(:all);

plan(3);
nan_ok(0 + "nan", 'nan_ok detects NaN');
ok((0 + "nan") != (0 + "nan"), 'NaN is not equal to itself');
ok((0 + "nan") != 1.0, 'NaN is not equal to a normal number');
