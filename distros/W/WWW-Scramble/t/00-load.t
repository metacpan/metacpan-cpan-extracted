#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'WWW::Scramble' );
}

diag( "Testing WWW::Scramble $WWW::Scramble::VERSION, Perl $], $^X" );
