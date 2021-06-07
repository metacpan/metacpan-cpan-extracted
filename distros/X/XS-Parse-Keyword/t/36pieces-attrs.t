#!/usr/bin/perl

use v5.14;
use warnings;

use Test::More;

use lib "t";
use testcase "t::pieces";

BEGIN { $^H{"t::pieces/permit"} = 1; }

{
   my $ret;

   $ret = pieceattrs;
   is( $ret, "", 'result of pieceattrs with none' );

   $ret = pieceattrs :foo :bar;
   is( $ret, ":foo():bar()", 'result of pieceattrs with two plain' );

   $ret = pieceattrs :one(1) :two(2);
   is( $ret, ":one(1):two(2)", 'result of pieceattrs with two + args' );

   $ret = pieceattrs : a b c;
   is( $ret, ":a():b():c()", 'result of pieceattrs with three no colons' );
}

done_testing;
