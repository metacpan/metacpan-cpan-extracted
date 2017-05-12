#!perl

use Test::More tests => 1;

BEGIN {
	use_ok( 'Test::Reporter::Transport::Metabase' );
}

diag( "Testing Test::Reporter::Transport::Metabase $Test::Reporter::Transport::Metabase::VERSION, Perl $], $^X" );
