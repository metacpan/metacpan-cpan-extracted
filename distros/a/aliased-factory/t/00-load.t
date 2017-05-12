
use warnings;
use strict;

use Test::More tests => 1;

my $package = 'aliased::factory';
use_ok('aliased::factory') or BAIL_OUT('cannot load aliased::factory');

eval {require version};
diag("Testing $package ", $package->VERSION );

# vim:syntax=perl:ts=2:sw=2:et:sta
