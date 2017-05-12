#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'WWW::NioTV' );
}

diag( "Testing WWW::NioTV $WWW::NioTV::VERSION, Perl $], $^X" );
