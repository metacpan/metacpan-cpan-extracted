#!/usr/bin/perl

use v5.14;
use warnings;

use Test::More;

use lib "t";
use testcase "t::func";

# named func
{
   func example { return 123; }

   is( example(), 123, 'named func' );
}

# anon func
{
   my $ex2 = func { return 456; };

   is( $ex2->(), 456, 'anon func' );
}

# func still obtains :ATTRS
{
   my $modify_invoked;

   sub MODIFY_CODE_ATTRIBUTES
   {
      my ( $pkg, $sub, $attr ) = @_;
      $modify_invoked++;
      Test::More::is( $attr, "MyCustomAttribute(value here)",
         'MODIFY_CODE_ATTRIBUTES takes attribute' );

      return ();
   }

   func withattr :MyCustomAttribute(value here) { }
   is( $modify_invoked, 1, 'MODIFY_CODE_ATTRIBUTES invoked' );
}

done_testing;
