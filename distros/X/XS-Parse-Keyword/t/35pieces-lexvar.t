#!/usr/bin/perl

use v5.14;
use warnings;

use Test2::V0;

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

   my $ret2 = piecelexvar $scalar;
   is( $ret2, $ret, 'result of piecelexvar matches previous' );
}

# intro_my()
{
   my $one = "outside";
   my $ret = piecelexvarmyintro $one in $one + 2;
   is( $ret, 3, 'result of piecelexvarmyintro' );
   is( $one, "outside", 'lexvar inside does not leak out' );
}

done_testing;
