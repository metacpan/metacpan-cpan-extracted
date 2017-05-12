use strict;

use Test::Number::Delta tests => 1;
delta_ok( 1.1e-6, 2e-6, "foo" );

