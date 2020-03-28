#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

use lib "t";
use testcase "t::stages";

our $VAR;
BEGIN { $^H{"t::stages/permit"} = 1; }

{
   BEGIN { $^H{'t::stages/pre_subparse-capture'} = 1; }

   BEGIN { $VAR = "before" }
   stages capture {
      BEGIN { $VAR = "inside" }
   }

   is( $t::stages::captured, "before",
      'captured value of $VAR before block' );
}

done_testing;
