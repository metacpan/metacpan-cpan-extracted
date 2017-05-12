#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'WWW::Shorten::Safe' );
}

diag( "Testing WWW::Shorten::Safe $WWW::Shorten::Safe::VERSION, Perl $], $^X" );

