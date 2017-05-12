# -*- perl -*-

# t/001_load.t - check module loading and create testing directory

use Test::More tests => 3;

use_ok( 'WWW::Marvel' );
use_ok( 'WWW::Marvel::Client' );
use_ok( 'WWW::Marvel::Config' );


