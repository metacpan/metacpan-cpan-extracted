use 5.008003;
use strict;
use warnings;
use lib 'lib';
use Test2::Bundle::Numerical qw(:all);

plan(3);
ok(get_tolerance() > 0, 'get_tolerance returns a positive value');
ok(get_tolerance(1) > 0, 'strict get_tolerance returns a positive value');
ok(get_tolerance(0) >= get_tolerance(1), 'non-strict tolerance is at least as large as strict tolerance');
