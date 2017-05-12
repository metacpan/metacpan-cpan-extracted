#!perl -Tw

use strict;
use warnings;
use Test::More tests => 1;

BEGIN {
    use_ok( 'WWW::RottenTomatoes' );
}

diag( "Testing WWW::RottenTomatoes $WWW::RottenTomatoes::VERSION" );
