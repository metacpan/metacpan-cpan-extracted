#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'WWW::Freshmeat' );
}

diag( "Testing WWW::Freshmeat $WWW::Freshmeat::VERSION, Perl $], $^X" );
