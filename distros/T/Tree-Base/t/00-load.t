
use warnings;
use strict;

use Test::More tests => 1;

my $package = 'Tree::Base';
use_ok('Tree::Base') or BAIL_OUT('cannot load Tree::Base');

eval {require version};
diag("Testing $package ", $package->VERSION );

# vim:syntax=perl:ts=2:sw=2:et:sta
