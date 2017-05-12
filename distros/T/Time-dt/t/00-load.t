
use warnings;
use strict;

use Test::More tests => 1;

my $package = 'Time::dt';
use_ok('Time::dt') or BAIL_OUT('cannot load Time::dt');

eval {require version};
diag("Testing $package ", $package->VERSION );

# vim:syntax=perl:ts=2:sw=2:et:sta
