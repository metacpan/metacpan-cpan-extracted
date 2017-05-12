#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'WWW::Dictionary' );
}

diag( "Testing WWW::Dictionary $WWW::Dictionary::VERSION, Perl $], $^X" );
