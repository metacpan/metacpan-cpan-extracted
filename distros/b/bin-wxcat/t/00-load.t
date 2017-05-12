
use warnings;
use strict;

use Test::More tests => 2;

my $package = 'bin::wxcat';
is(require('./bin/wxcat'), $package) or
  BAIL_OUT("cannot load $package");
use_ok($package);

eval {require version};
diag("Testing $package ", $package->VERSION );

# vim:syntax=perl:ts=2:sw=2:et:sta
