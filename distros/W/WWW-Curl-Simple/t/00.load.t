#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'WWW::Curl::Simple' );
}

diag( "Testing WWW::Curl::Simple $WWW::Curl::Simple::VERSION, Perl $], $^X" );
