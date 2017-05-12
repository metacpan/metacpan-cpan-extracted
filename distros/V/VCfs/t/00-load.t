
use warnings;
use strict;

use Test::More tests => 1;

my $package = 'VCfs';
use_ok('VCfs') or BAIL_OUT('cannot load VCfs');

eval {require version};
diag("Testing $package ", $package->VERSION );

# vim:syntax=perl:ts=2:sw=2:et:sta
