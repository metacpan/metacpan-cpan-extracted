#!/usr/bin/perl

use v5.14;
use warnings;

use Test2::V0;

use lib "t";
use testcase "t::structures";

BEGIN { $^H{"t::structures/permit"} = 1; }

# parens
{
   is( parens ( "abc" ), "abc", 'parenthesis container' );
}

# args - parens are optional
{
   is( args ( "123" ), "123", 'arguments container with parens' );
   is( args "123",     "123", 'arguments container without parens' );
}

# brackets
{
   is( brackets [ "def" ], "def", 'bracket container' );
}

# braces
{
   is( braces { "ghi" }, "ghi", 'brace container' );
}

# chevrons
{
   # takes a bareword identifier
   is( chevrons < jkl >, "jkl", 'chevron container' );
}

done_testing;
