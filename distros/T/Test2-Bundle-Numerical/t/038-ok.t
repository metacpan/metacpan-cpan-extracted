use 5.008003;
use strict;
use warnings;
use lib 'lib';
use Test2::Bundle::Numerical qw(:all);

plan(2);

ok(1, 'ok passes true values');
ok(!0, 'ok fails false values');
