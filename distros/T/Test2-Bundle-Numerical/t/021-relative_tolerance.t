use 5.008003;
use strict;
use warnings;
use lib 'lib';
use Test2::Bundle::Numerical qw(:all);

plan(3);
ok(relative_tolerance(4) > 0, 'relative_tolerance returns positive tolerance');
ok(relative_tolerance(8) > relative_tolerance(4), 'larger ULP count gives larger tolerance');
ok(relative_tolerance(1) <= relative_tolerance(4), 'smaller ULP count gives smaller or equal tolerance');
