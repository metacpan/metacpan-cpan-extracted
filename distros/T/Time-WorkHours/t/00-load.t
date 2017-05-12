#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Time::WorkHours' );
}

diag( "Testing Time::WorkHours $Time::WorkHours::VERSION, Perl $], $^X" );
