#!/usr/bin/perl

use v5.14;
use warnings;

use Test2::V0;

use lib "t";
use testcase "t::func";

BEGIN { $^H{"t::func/func"}++ }

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
      ::is( $attr, "MyCustomAttribute(value here)",
         'MODIFY_CODE_ATTRIBUTES takes attribute' );

      return ();
   }

   func withattr :MyCustomAttribute(value here) { }
   is( $modify_invoked, 1, 'MODIFY_CODE_ATTRIBUTES invoked' );
}

# named func in another package
{
   func Some::Other::Package::example { return 456; }

   is( Some::Other::Package->example, 456, 'named func in another package' );

   my $e = defined eval 'nopkgfunc Some::Other::Package::example2 { }; 1' ? undef : $@;
   like( $e, qr/^Declaring this sub-like function in another package is not permitted /,
      'nopkgfunc does not permit other package name' );
}

done_testing;
