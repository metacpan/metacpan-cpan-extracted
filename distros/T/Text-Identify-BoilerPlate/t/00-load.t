#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Text::Identify::BoilerPlate' );
}

diag( "Testing Text::Identify::BoilerPlate $Text::Identify::BoilerPlate::VERSION, Perl $], $^X" );
