#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'WWW::ItsABot' );
}

diag( "Testing WWW::ItsABot $WWW::ItsABot::VERSION, Perl $], $^X" );
