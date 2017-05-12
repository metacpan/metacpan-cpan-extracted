#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'XML::CompactTree' );
}

diag( "Testing XML::CompactTree $XML::CompactTree::VERSION, Perl $], $^X" );
