#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Test::Run::Plugin::CollectStats' );
}

diag( "Testing Test::Run::Plugin::CollectStats $Test::Run::Plugin::CollectStats::VERSION, Perl $], $^X" );
