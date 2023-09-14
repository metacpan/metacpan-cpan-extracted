#!/usr/bin/perl

use v5.14;
use warnings;

use Test2::V0;
BEGIN {
   $] >= 5.026000 or plan skip_all => "No parse_subsignature()";

   eval { require Future::AsyncAwait;
          Future::AsyncAwait->VERSION( '0.66' );
          1; } or
       plan skip_all => "No Future::AsyncAwait";

   Future::AsyncAwait->import;
}

use feature 'signatures';
no warnings 'experimental';

use Sublike::Extended;

# async extended sub
{
   async extended sub f (:$x, :$y) { return "x=$x y=$y" }

   is( await f( x => "first", y => "second" ), "x=first y=second",
      'async extended sub' );
}

done_testing;
