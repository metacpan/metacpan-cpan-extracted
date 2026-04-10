use 5.008003;
use strict;
use warnings;
use lib 'lib';
use Test2::Bundle::Numerical qw(:all);

plan(3);
is_infinite(1e999, 'is_infinite detects positive infinity');
ok(!is_infinite(1.0), 'is_infinite rejects finite values');
is_infinite(-1e999, 'is_infinite detects negative infinity');
