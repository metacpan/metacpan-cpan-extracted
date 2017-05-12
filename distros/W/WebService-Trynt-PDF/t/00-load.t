#!perl -T

use Test::More tests => 2;

BEGIN {
	use_ok( 'WebService::Trynt::PDF' );
	use_ok( 'WebService::Trynt::PDF::File' );
}

diag( "Testing WebService::Trynt::PDF $WebService::Trynt::PDF::VERSION, Perl $], $^X" );
