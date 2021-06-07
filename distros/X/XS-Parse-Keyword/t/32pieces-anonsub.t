#!/usr/bin/perl

use v5.14;
use warnings;

use Test::More;

use lib "t";
use testcase "t::pieces";

BEGIN { $^H{"t::pieces/permit"} = 1; }

{
   my $ret = pieceanonsub { "sub value" };
   is( ref $ret, "CODE", 'result of pieceanonsub is CODE reference' );
   is( $ret->(), "sub value", 'result of invoking' );
}

done_testing;
