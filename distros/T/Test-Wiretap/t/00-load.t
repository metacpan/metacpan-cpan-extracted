#!perl -T

use Test::More tests => 1;

use lib 't/lib';
use lib 'lib';
use lib '../lib';

BEGIN {
	use_ok( 'Test::Wiretap' );
}

diag( "Testing Test::Wiretap $Test::Wiretap::VERSION, Perl $], $^X" );
