#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'WWW::Rapidshare::Free' );
}

diag( "Testing WWW::Rapidshare::Free $WWW::Rapidshare::Free::VERSION, Perl $], $^X" );
