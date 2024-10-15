#!/usr/bin/perl

use v5.14;
use warnings;

use Test2::V0;
BEGIN { $] >= 5.026000 or plan skip_all => "No parse_subsignature()"; }

use Test2::Require::Module 'Future::AsyncAwait' => '0.66';
use Test2::Require::Module 'Sublike::Extended' => '0.29';

use feature 'signatures';
no warnings 'experimental';

use Future::AsyncAwait;
use Sublike::Extended;

# async extended sub
{
   async extended sub f1 (:$x, :$y) { return "x=$x y=$y" }

   is( await f1( x => "first", y => "second" ), "x=first y=second",
      'async extended sub' );
}

# async sub + S:E 0.29
{
   use Sublike::Extended 'sub';

   async sub f2 (:$x, :$y) { return "x=$x y=$y" }

   is( await f2( x => "third", y => "fourth" ), "x=third y=fourth",
      'async sub with extended keyword' );
}

done_testing;
