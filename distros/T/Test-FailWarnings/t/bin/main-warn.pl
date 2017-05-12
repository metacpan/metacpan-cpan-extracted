use strict;
use warnings;
use Test::More;
use Test::FailWarnings;

ok( 1,              "first test" );
ok( 1 + "lkadjaks", "add non-numeric" );

done_testing;
