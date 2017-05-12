#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Test::Run::Plugin::BreakOnFailure' );
}

diag( "Testing Test::Run::Plugin::BreakOnFailure $Test::Run::Plugin::BreakOnFailure::VERSION, Perl $], $^X" );
