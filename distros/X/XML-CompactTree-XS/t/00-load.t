#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'XML::CompactTree::XS' );
}

diag( "Testing XML::CompactTree::XS $XML::CompactTree::XS::VERSION, Perl $], $^X" );
