#!perl

use Test::More tests => 1;

BEGIN {
	use_ok( 'Test::Run::CmdLine' );
}

diag( "Testing Test::Run::CmdLine $Test::Run::CmdLine::VERSION, Perl $], $^X" );
