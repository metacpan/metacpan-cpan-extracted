#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'WWW::LargeFileFetcher' );
}

diag( "Testing WWW::LargeFileFetcher $WWW::LargeFileFetcher::VERSION, Perl $], $^X" );
