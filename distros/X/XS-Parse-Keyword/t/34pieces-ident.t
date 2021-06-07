#!/usr/bin/perl

use v5.14;
use warnings;

use Test::More;

use lib "t";
use testcase "t::pieces";

BEGIN { $^H{"t::pieces/permit"} = 1; }

{
   my $ret = pieceident foobar;
   is( $ret, "foobar", 'result of pieceident' );
}

{
   my $ret = piecepkg Bar::Foo;
   is( $ret, "Bar::Foo", 'result of piecepkg' );
}

done_testing;
