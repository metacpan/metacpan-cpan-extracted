#!/usr/bin/perl

use v5.14;
use warnings;

use Test::More;

use lib "t";
use testcase "t::pieces";

BEGIN { $^H{"t::pieces/permit"} = 1; }

my $ret;

{
   $ret = piecelistexpr "a term";
   is( $ret, "a term", 'a single term' );
}

# listexpr vs concat
{
   $ret = piecelistexpr "x" . "y";
   is( $ret, "xy", 'listexpr consumes concat' );
}

# listexpr vs comma
{
   $ret = join "", "x", piecelistexpr "inside", "y";
   is( $ret, "xinside,y", 'listexpr consumes comma' );
}

done_testing;
