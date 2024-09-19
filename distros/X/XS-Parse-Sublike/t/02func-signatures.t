#!/usr/bin/perl

use v5.14;
use warnings;

use Test2::V0;
BEGIN {
   $] >= 5.026000 or plan skip_all => "No parse_subsignature()";
}

use feature 'signatures';
no warnings 'experimental';

use lib "t";
use testcase "t::func";

BEGIN { $^H{"t::func/func"}++ }

# basic sig
{
   func withparam($x) { return $x + 1 }

   is( withparam( 4 ), 5, 'func with param' );
}

# The following are additional tests that our pre-5.31.3 backported
# parse_subsignature() works correctly
{
   func sum(@x) {
      my $ret = 0;
      $ret += $_ for @x;
      return $ret;
   }

   is( sum( 10, 20, 30 ), 60, 'func with slurpy parameter' );

   func firstandthird($x, $, $z) {
      return $x . $z;
   }

   is( firstandthird(qw( a b c )), "ac", 'func with unnamed parameter' );

   func withoptparam($one = 1) { return $one + 2 }

   is( withoptparam,      3, 'func with optional param missing' );
   is( withoptparam( 2 ), 4, 'func with optional param present' );

   func has_whitespace (
      $x
   ) {
      return $x;
   }

   is( has_whitespace( "value" ), "value", 'func with whitespace in signature' );

   # RT132284
   func noparams() { return "constant" }

   is( noparams, "constant", 'func with no params' );
   like( dies { noparams( 1, 2, 3 ) },
      # message was extended somewhere in perl 5.33
      qr/^Too many arguments for subroutine 'main::noparams' (\(.*\) )?at /,
      'Exception thrown from empty signature validation failure' );
}

# RT131571
{
   func withattr :method ($self, @args) { }

   ok( scalar( grep { m/^method$/ } attributes::get( \&withattr ) ),
      'func with attr and signture does not collide' );
}

# RT155630
{
   my $var = "outside";
   func defaultfromoutside($var = $var) { return $var; }

   is( defaultfromoutside(), "outside",
      'variable in defaulting expression is not shadowed by its own parameter' );

   # Not directly related to this bug but we might as well test this too
   func defaultfromfirst($x, $y = $x) { return $y; }

   is( defaultfromfirst( "first" ), "first",
      'variable in later defaulting expression can see earlier params' );
}

done_testing;
