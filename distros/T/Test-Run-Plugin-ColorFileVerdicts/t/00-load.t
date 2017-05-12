#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Test::Run::Plugin::ColorFileVerdicts' );
}

diag( "Testing Test::Run::Plugin::ColorFileVerdicts $Test::Run::Plugin::ColorFileVerdicts::VERSION, Perl $], $^X" );
