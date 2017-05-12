#!perl -T

use Test::More tests => 2;

BEGIN {
        use_ok( 'Dancer', qw(!pass)) or
	    diag( "This module depends on Dancer.pm" );
	use_ok( 'Web::DataService' );
}

diag( "Testing Web::DataService $Web::DataService::VERSION, Perl $], $^X" );
