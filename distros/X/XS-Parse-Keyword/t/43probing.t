#!/usr/bin/perl

use v5.14;
use warnings;

use Test::More;

use lib "t";
use testcase "t::probing";

BEGIN { $^H{"t::probing/permit"} = 1; }

# colon
{
   ok( !probecolon, 'colon absent' );
   ok( probecolon :, 'colon present' );
}

# literal
{
   ok( !probeliteral, 'literal absent' );
   ok( probeliteral literal, 'literal present' );
}

# block
{
   ok( !probeblock, 'block absent' );
   ok( probeblock {}, 'block present' );
}

# vstring
{
   ok( !probevstring, 'vstring absent' );
   ok( probevstring v1.2.3, 'vstring present' );
}

# choice
{
   ok( !probechoice, 'choice absent' );
   ok( probechoice x, '1st choice present' );
   ok( probechoice z, '2nd choice present' );
}

# tagged choice
{
   ok( !probetaggedchoice, 'tagged choice absent' );
   ok( probetaggedchoice x, '1st tagged choice present' );
   ok( probetaggedchoice z, '2nd tagged choice present' );
}

# paren scope
{
   ok( !probeparens, 'parens absent' );
   ok( probeparens (123), 'parens present' );
}

# bracket scope
{
   ok( !probebrackets, 'brackets absent' );
   ok( probebrackets [123], 'brackets present' );
}

# brace scope
{
   ok( !probebraces, 'braces absent' );
   ok( probebraces {123}, 'braces present' );
}

# chevron scope
{
   ok( !probechevrons, 'chevrons absent' );
   ok( probechevrons <abc>, 'chevrons present' );
}

done_testing;
