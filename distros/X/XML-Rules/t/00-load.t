#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'XML::Rules' );
}

diag( "Testing XML::Rules $XML::Rules::VERSION, Perl $], $^X" );
