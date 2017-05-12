use strict;
use warnings;
use Test::More;

use UUID::Object;
plan skip_all
  => sprintf("Unsupported UUID::Object (%.2f) is installed.",
             $UUID::Object::VERSION)
  if $UUID::Object::VERSION > 0.80;

plan tests => 1;

eval q{ use UUID::Generator::PurePerl::RNG; };
die if $@;

my $g = UUID::Generator::PurePerl::RNG->new();
my $x = 0;
for (1 .. 10) {
    my $r = $g->rand_32bit;
    $x |= $r;
}
# $x will be 0 in 1e-100 probability

ok( $x != 0, 'random data' );
