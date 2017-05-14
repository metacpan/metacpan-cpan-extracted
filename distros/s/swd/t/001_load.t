# -*- perl -*-

# t/001_load.t - check module loading 

use Test::More tests => 1;

INIT{ use_ok( 'swd' ); }


