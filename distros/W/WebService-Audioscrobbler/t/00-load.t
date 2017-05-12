#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'WebService::Audioscrobbler' );
}

diag( "Testing WebService::Audioscrobbler $WebService::Audioscrobbler::VERSION, Perl $], $^X" );
