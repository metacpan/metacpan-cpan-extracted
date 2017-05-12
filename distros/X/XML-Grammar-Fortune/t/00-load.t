#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'XML::Grammar::Fortune' );
}

diag( "Testing XML::Grammar::Fortune $XML::Grammar::Fortune::VERSION, Perl $], $^X" );
