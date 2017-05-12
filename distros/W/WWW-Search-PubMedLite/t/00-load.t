#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'WWW::Search::PubMedLite' );
}

diag( "Testing WWW::Search::PubMedLite $WWW::Search::PubMedLite::VERSION, Perl $], $^X" );
