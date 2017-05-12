#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'WWW::FreeProxy' );
}

diag( "Testing WWW::FreeProxy $WWW::FreeProxy::VERSION, Perl $], $^X" );
