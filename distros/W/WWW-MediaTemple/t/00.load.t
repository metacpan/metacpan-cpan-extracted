#!perl -Tw

use strict;
use warnings;
use Test::More tests => 1;

BEGIN {
        use_ok( 'WWW::MediaTemple' );
}

diag( "Testing WWW::MediaTemple $WWW::MediaTemple::VERSION" );
