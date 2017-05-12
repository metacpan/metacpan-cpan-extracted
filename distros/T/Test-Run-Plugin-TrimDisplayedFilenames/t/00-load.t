#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Test::Run::Plugin::TrimDisplayedFilenames' );
}

diag( "Testing Test::Run::Plugin::TrimDisplayedFilenames $Test::Run::Plugin::TrimDisplayedFilenames::VERSION, Perl $], $^X" );
