use strict;
use warnings;
use Test::More;

use UUID::Object;
plan skip_all
  => sprintf("Unsupported UUID::Object (%.2f) is installed.",
             $UUID::Object::VERSION)
  if $UUID::Object::VERSION > 0.80;

plan tests => 5 * 6;

eval q{ use UUID::Generator::PurePerl::Util; };
die if $@;

for my $len (1 .. 6) {
    for my $i (1 .. 5) {
        my $d = digest_as_octets($len, q{} . rand);

        is( length($d), $len, "digest_as_octets(${len}): trial ${i}" );
    }
}

