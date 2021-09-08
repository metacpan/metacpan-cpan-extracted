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

   $ret = pieceinfix ==;
   is( $ret, "eq", 'result of piecelexvarname' );

   $ret = pieceinfix gt;
   is( $ret, "sgt", 'result of piecelexvarname' );

   $ret = pieceinfixeq eq;
   is( $ret, "seq", 'result of piecelexvarname' );

   ok( !defined eval "pieceinfixeq >",
      'pieceinfixeq does not accept >' );
   like( $@, qr/^Expected an infix operator at /, 'message from pieceinfixeq' );
}

done_testing;
