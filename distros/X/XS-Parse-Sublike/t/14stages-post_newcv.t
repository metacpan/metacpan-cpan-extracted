#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

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
