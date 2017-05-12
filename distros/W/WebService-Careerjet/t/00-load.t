#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'WebService::Careerjet' );
}

diag( "Testing WebService::Careerjet $WebService::Careerjet::VERSION, Perl $], $^X" );
