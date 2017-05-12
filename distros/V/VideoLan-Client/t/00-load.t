#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'VideoLan::Client' );
}

diag( "Testing VideoLan::Client $VideoLan::Client::VERSION, Perl $], $^X" );
