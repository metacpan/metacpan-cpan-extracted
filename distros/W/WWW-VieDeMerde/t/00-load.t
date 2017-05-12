#!perl -T

use Test::More tests => 2;

BEGIN {
	use_ok( 'WWW::VieDeMerde' );
	use_ok( 'WWW::VieDeMerde::Message' )
}

diag( "Testing WWW::VieDeMerde $WWW::VieDeMerde::VERSION, Perl $], $^X" );
