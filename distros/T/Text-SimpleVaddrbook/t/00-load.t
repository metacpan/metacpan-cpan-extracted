#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Text::SimpleVaddrbook' );
}

diag( "Testing Text::SimpleVaddrbook $Text::SimpleVaddrbook::VERSION, Perl $], $^X" );
