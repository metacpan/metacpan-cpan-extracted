use warnings;
use strict;

use ToolSet::Math;

use Test::More tests => 9;

# base-2 logarithm
{
    is( log2(1), 0 );
    is( log2(2), 1 );
    is( log2(4), 2 );
    is( log2(8), 3 );
}

# factorial
{
    is( fac(0), 1 );
    is( fac(1), 1 );
    is( fac(2), 2 );
    is( fac(4), 24 );
    is( fac(10), 3628800 );
}
