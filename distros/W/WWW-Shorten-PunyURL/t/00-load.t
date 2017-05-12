#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'WWW::Shorten::PunyURL' );
}

diag( "Testing WWW::Shorten::PunyURL $WWW::Shorten::PunyURL::VERSION, Perl $], $^X" );
