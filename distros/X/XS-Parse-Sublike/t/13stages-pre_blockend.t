#!/usr/bin/perl

use v5.14;
use warnings;

use Test::More;

use lib "t";
use testcase "t::stages";

our $VAR;
BEGIN { $^H{"t::stages/permit"} = 1; }

{
   BEGIN { $^H{'t::stages/pre_blockend-capture'} = 1; }

   BEGIN { $VAR = "before" }
   stages capture {
      BEGIN { $VAR = "inside" }
   }

   is( $t::stages::captured, "inside",
      'captured value of $VAR inside block' );
}

done_testing;
