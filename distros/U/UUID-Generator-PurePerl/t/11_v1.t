use strict;
use warnings;
use Test::More;

use UUID::Object;
plan skip_all
  => sprintf("Unsupported UUID::Object (%.2f) is installed.",
             $UUID::Object::VERSION)
  if $UUID::Object::VERSION > 0.80;

plan tests => 1;

eval q{ use UUID::Generator::PurePerl; };
die if $@;

my $g = UUID::Generator::PurePerl->new();

my $u1 = $g->generate_v1();
my $u2 = $g->generate_v1();

ok( $u1 != $u2, 'UUIDs differ' );

# TODO: write more test
