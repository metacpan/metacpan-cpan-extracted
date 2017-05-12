
use warnings;
use strict;

use Test::More tests => 1;

my $package = 'Text::Slidez';
use_ok('Text::Slidez') or BAIL_OUT('cannot load Text::Slidez');

eval {require version};
diag("Testing $package ", $package->VERSION );

# vim:syntax=perl:ts=2:sw=2:et:sta
