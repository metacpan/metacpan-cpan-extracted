#!/usr/bin/perl

use v5.14;
use warnings;

use Test2::V0;

use lib "t";
use testcase "t::stages";

BEGIN { $^H{"t::stages/permit"} = 1; }

{
   BEGIN { $^H{'t::stages/post_newcv-capture-cv'} = 1; }

   stages capture { }

   is( $t::stages::captured, \&capture,
      'captured value of new CV' );
}

done_testing;
