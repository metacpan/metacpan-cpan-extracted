#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'WWW::Dict::TWMOE::Phrase' );
}

diag( "Testing WWW::Dict::TWMOE::Phrase $WWW::Dict::TWMOE::Phrase::VERSION, Perl $], $^X" );
