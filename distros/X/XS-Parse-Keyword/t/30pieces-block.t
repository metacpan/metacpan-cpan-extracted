#!/usr/bin/perl

use v5.14;
use warnings;

use Test::More;

use lib "t";
use testcase "t::pieces";

BEGIN { $^H{"t::pieces/permit"} = 1; }

{
   my $ret = pieceblock { "block value" };
   is( $ret, "(block value)", 'result of pieceblock' );
}

done_testing;
