use 5.008003;
use strict;
use warnings;
use lib 'lib';
use Test2::Bundle::Numerical qw(:all);

plan(3);
ok(nv_digits() > 0, 'nv_digits returns a positive integer');
is(nv_digits(), nv_info()->{digits}, 'nv_digits matches nv_info digits');
ok(nv_digits() >= 15, 'nv_digits is at least 15 for expected NV precision');
