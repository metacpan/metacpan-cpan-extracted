#!/usr/bin/perl

use v5.14;
use warnings;

use Test2::V0;

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

# termexpr in piece1 can act as eat empty parens
{
   no warnings 'uninitialized';

   $ret = piecetermexpr() . "y";
   is( $ret, "()y", 'termexpr accepts empty (PARENS)' );
}

{
   $ret = pieceprefixedtermexpr_VAR $VAR . ", world!";
   is( $ret, "(Hello, world!)", 'result of pieceprefixedtermexpr_VAR' );
}

# optional termexpr
{
   my $ret1 = piecetermexpr_opt "term";
   my $ret2 = piecetermexpr_opt;

   is( $ret1, "(term)", 'optional termexpr with value' );
   is( $ret2, undef,    'optional termexpr empty' );
}

done_testing;
