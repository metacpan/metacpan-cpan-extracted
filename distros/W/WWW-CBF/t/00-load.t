#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'WWW::CBF' );
}

diag( "Testing WWW::CBF $WWW::CBF::VERSION, Perl $], $^X" );
