#!perl -T

use Test::More tests => 2;
use Test::NoWarnings;

BEGIN {
	use_ok( 'Test::XML::Deep' );
}

diag( "Testing Test::XML::Deep $Test::XML::Deep::VERSION, Perl $], $^X" );
