#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'XHTML::Util' );
}

diag( "Testing XHTML::Util $XHTML::Util::VERSION, Perl $], $^X" );
