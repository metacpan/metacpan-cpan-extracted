#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'WWW::Search::DrugBank' );
}

diag( "Testing WWW::Search::DrugBank $WWW::Search::DrugBank::VERSION, Perl $], $^X" );
