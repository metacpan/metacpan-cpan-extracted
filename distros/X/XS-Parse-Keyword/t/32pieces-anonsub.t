#!/usr/bin/perl

use v5.14;
use warnings;

use Test2::V0;

use lib "t";
use testcase "t::pieces";

BEGIN { $^H{"t::pieces/permit"} = 1; }

{
   my $ret = pieceanonsub { "sub value" };
   is( ref $ret, "CODE", 'result of pieceanonsub is CODE reference' );
   is( $ret->(), "sub value", 'result of invoking' );
}

{
   my $ret = piecestagedanonsub { return "$VAR, world" };

   is( ref $ret, "CODE", 'result of piecestagedanonsub is CODE reference' );
   is( $ret->(), "Hello, world", 'result of invoking' );

   is( $::STAGES, "PREPARE,START,END,WRAP", 'All ANONSUB stages were invoked' );
}

done_testing;
