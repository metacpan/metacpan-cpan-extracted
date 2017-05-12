use strict;
use Test::More tests => 2;

require_ok("Test::Number::Delta");

eval { Test::Number::Delta->import( tests => 1, within => 1e-4 ) };
ok( $@, "dies if parameter is given after test plan" );

