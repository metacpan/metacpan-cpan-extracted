use 5.008003;
use strict;
use warnings;
use lib 'lib';
use Test2::Bundle::Numerical qw(:all);

plan(3);
ok(nv_epsilon() > 0, 'nv_epsilon returns a positive value');
is(nv_epsilon(), nv_info()->{machine_epsilon}, 'nv_epsilon matches nv_info machine_epsilon');
ok(length(sprintf('%g', nv_epsilon())) > 0, 'nv_epsilon returns a numeric string value');
