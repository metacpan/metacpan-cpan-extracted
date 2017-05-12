#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'TiVo::Calypso' );
}

diag( "Testing TiVo::Calypso $TiVo::Calypso::VERSION, Perl $], $^X" );

