#!perl

use Test::More tests => 1;

BEGIN {
	use_ok( 'WWW::Mechanize::Meta' );
}

diag( "Testing WWW::Mechanize::Meta $WWW::Mechanize::Meta::VERSION, Perl $], $^X" );
