#!/usr/bin/perl

use v5.14;
use warnings;

use Test::More;

use lib "t";
use testcase "t::structures";

BEGIN { $^H{"t::structures/permit"} = 1; }

# optional
{
   is( structoptional part, 1, 'optional present' );
   is( structoptional,      0, 'optional absent' );
}

# repeated
{
   is( structrepeat part part, 2, 'repeated twice' );
   is( structrepeat part part part part, 4, 'repeated four times' );
}

# choice
{
   is( structchoice zero, 0, 'choice zero' );
   is( structchoice two, 2, 'choice two' );
   is( structchoice, -1, 'choice absent' );
}

# tagged choice
{
   is( structtagged one, 1, 'tagged choice one' );
   is( structtagged three, 3, 'tagged choice three' );
}

done_testing;
