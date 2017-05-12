
use warnings;
use strict;

use Test::More tests => 1;

my $package = 'XML::Bits';
use_ok('XML::Bits') or BAIL_OUT('cannot load XML::Bits');

eval {require version};
diag("Testing $package ", $package->VERSION );

# vim:syntax=perl:ts=2:sw=2:et:sta
