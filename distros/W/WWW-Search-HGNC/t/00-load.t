#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'WWW::Search::HGNC' );
}

diag( "Testing WWW::Search::HGNC $WWW::Search::HGNC::VERSION, Perl $], $^X" );
