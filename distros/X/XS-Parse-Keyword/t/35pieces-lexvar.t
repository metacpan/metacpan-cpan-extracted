#!/usr/bin/perl

use v5.14;
use warnings;

use Test::More;

use lib "t";
use testcase "t::pieces";

BEGIN { $^H{"t::pieces/permit"} = 1; }

# names
{
   my $ret;

   $ret = piecelexvarname $scalar;
   is( $ret, "\$scalar", 'result of piecelexvarname' );

   $ret = piecelexvarname @array;
   is( $ret, "\@array", 'result of piecelexvarname' );

   $ret = piecelexvarname %hash;
   is( $ret, "\%hash", 'result of piecelexvarname' );
}

# pad indexes
{
   my $ret;

   $ret = piecelexvarmy $scalar;
   cmp_ok( $ret, '>', 0, 'result of piecelexvarmy' );

   $scalar = 123;
}

done_testing;
