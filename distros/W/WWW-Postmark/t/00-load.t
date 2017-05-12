#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'WWW::Postmark' ) || print "Bail out!\n";
}

diag( "Testing WWW::Postmark $WWW::Postmark::VERSION, Perl $], $^X" );
