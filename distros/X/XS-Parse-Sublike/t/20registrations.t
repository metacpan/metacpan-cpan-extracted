#!/usr/bin/perl

use v5.14;
use warnings;

use Test::More;

use lib "t";
use testcase "t::registrations";

# Check the individual `func` registrations do not clash
{
   {
      BEGIN { $^H{"t::registrations/red"} = 1 }
      func returns_red { }
   }
   {
      BEGIN { $^H{"t::registrations/blue"} = 1 }
      func returns_blue { }
   }

   is( returns_red(),  "red",  'returns red' );
   is( returns_blue(), "blue", 'returns blue' );
}

done_testing;
