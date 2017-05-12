use strict;
use warnings;
use Test::More;
use Test::FailWarnings -allow_deps => 1;

use constant AUTOLOAD => 1;

is( AUTOLOAD(), 1, "AUTOLOAD turned into a constant" );

done_testing;
