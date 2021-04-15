#!/usr/bin/perl

use v5.14;
use warnings;

use Test::More;

use lib "t";
use testcase "t::pieces";

BEGIN { $^H{"t::pieces/permit"} = 1; }

my $ret;

{
   $ret = piecetermexpr "a term";
   is( $ret, "(a term)", 'a single term' );
}

# termexpr vs concat
{
   $ret = piecetermexpr "x" . "y";
   is( $ret, "(xy)", 'termexpr consumes concat' );
}

# termexpr vs comma
{
   $ret = join "", "x", piecetermexpr "inside", "y";
   is( $ret, "x(inside)y", 'termexpr stops before comma' );
}

# termexpr in piece1 can act as entire parens
{
   $ret = piecetermexpr( "x" ) . "y";
   is( $ret, "(x)y", 'termexpr treats (PARENS) as entire expression' );
}

done_testing;
