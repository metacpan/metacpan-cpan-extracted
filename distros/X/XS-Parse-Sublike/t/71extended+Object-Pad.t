#!/usr/bin/perl

use v5.14;
use warnings;

use Test2::V0;
BEGIN {
   $] >= 5.026000 or plan skip_all => "No parse_subsignature()";

   eval { require Object::Pad;
          Object::Pad->VERSION( '0.800' );
          1; } or
       plan skip_all => "No Object::Pad";

   Object::Pad->import;
}

use Sublike::Extended;

# extended method
{
   class C1 {
      extended method f (:$x, :$y) { return "x=$x y=$y" }
   }

   is( C1->new->f( x => "first", y => "second" ), "x=first y=second",
      'async method' );
}

done_testing;
