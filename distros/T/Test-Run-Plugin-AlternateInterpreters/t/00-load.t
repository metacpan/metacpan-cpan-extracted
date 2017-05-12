#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Test::Run::Plugin::AlternateInterpreters' );
}

diag( "Testing Test::Run::Plugin::AlternateInterpreters $Test::Run::Plugin::AlternateInterpreters::VERSION, Perl $], $^X" );
