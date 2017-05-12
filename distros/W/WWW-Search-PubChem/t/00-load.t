#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'WWW::Search::PubChem' );
}

diag( "Testing WWW::Search::PubChem $WWW::Search::PubChem::VERSION, Perl $], $^X" );
