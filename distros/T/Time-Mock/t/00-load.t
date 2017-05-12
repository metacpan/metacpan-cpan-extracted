
use warnings;
use strict;

use Test::More tests => 1;

my $package = 'Time::Mock';
use_ok('Time::Mock') or BAIL_OUT('cannot load Time::Mock');

eval {require version};
diag("Testing $package ", $package->VERSION );

# vim:syntax=perl:ts=2:sw=2:et:sta
