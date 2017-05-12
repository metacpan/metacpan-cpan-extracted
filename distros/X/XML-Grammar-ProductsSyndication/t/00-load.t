#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'XML::Grammar::ProductsSyndication' );
}

diag( "Testing XML::Grammar::ProductsSyndication $XML::Grammar::ProductsSyndication::VERSION, Perl $], $^X" );
