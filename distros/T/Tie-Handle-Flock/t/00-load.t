#!perl -T

use lib './lib';
use lib '../lib';
use Test::More tests => 1;

BEGIN {
	use_ok( 'Tie::Handle::Flock' );
}

diag( "Testing Tie::Handle::Flock $Tie::Handle::Flock::VERSION, Perl $], $^X" );
