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

use Sublike::Extended;

use feature 'class';
no warnings 'experimental::class';

# extended method
{
   class C1 {
      extended method f (:$x, :$y) { return "x=$x y=$y" }
   }

   is( C1->new->f( x => "first", y => "second" ), "x=first y=second",
      'async method' );
}

done_testing;
