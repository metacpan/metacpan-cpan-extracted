#!/usr/bin/perl

use v5.14;
use warnings;

use Test2::V0;
BEGIN {
   $] >= 5.026000 or plan skip_all => "No parse_subsignature()";

   # version 5.37.10 added the ability to start_subparse() with CVf_IsMETHOD,
   # which we need
   plan skip_all => "feature 'class' is not available"
      unless $^V ge v5.37.10;
}

use Test2::Require::Module 'Sublike::Extended' => '0.29';

use Sublike::Extended;

use feature 'class';
no warnings 'experimental::class';

# extended method
{
   class C1 {
      extended method f (:$x, :$y) { return "x=$x y=$y" }
   }

   is( C1->new->f( x => "first", y => "second" ), "x=first y=second",
      'extended method' );
}

# method + S:E 0.29
{
   use Sublike::Extended 'method';

   class C2 {
      method self   { return $self }

      # Perl GH #24773 suggests we need to test a few variants
      method f0p ()         { return "(null)" }
      method f1p ($x)       { return "[1]=$x" }
      method f2n (:$x, :$y) { return "x=$x y=$y" }
   }

   my $o = C2->new;
   is( $o->self, $o, 'method with extended keyword can see $self' );

   is( $o->f0p(), "(null)",
      'method with extended keyword and 0 positional params' );
   is( $o->f1p( "arg" ), "[1]=arg",
      'method with extended keyword and 1 positional param' );
   is( $o->f2n( x => "third", y => "fourth" ), "x=third y=fourth",
      'method with extended keyword and 2 named params' );
}

done_testing;
