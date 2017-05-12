# -*- perl -*-

use strict;
use warnings;
use Test::More tests => 2;
use Tie::Array::BoundedIndex;

my $mod_not_available;

BEGIN {
  eval 'require Attribute::Handlers'
   or $mod_not_available = 'Attribute::Handlers';
  defined eval "require $_ and $_->import" or $mod_not_available = $_
    for 'Test::Exception';
}

SKIP: {
  $mod_not_available and skip "$mod_not_available not installed", 2;

  dies_ok { my @x : Bounded(foo => 42) } "Illegal arguments exception";

  my @x : Bounded(upper => 5);
  @x = (0..5);
  throws_ok { push @x, "too big" } qr/out of range/, "Push exception";
}
