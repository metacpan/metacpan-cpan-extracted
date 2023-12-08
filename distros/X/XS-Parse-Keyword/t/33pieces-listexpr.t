#!/usr/bin/perl

use v5.14;
use warnings;

use Test2::V0;

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

# optional listexpr
{
   my $ret1 = piecelistexpr_opt 1, 2, 3;
   my $ret2 = piecelistexpr_opt;

   is( $ret1, "1,2,3", 'optional listexpr with values' );
   is( $ret2, undef,   'optional listexpr empty' );
}

done_testing;
