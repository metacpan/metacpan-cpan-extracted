#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'WebService::Geocodio' ) || print "Bail out!\n";
}

diag( "Testing WebService::Geocodio $WebService::Geocodio::VERSION, Perl $], $^X" );
