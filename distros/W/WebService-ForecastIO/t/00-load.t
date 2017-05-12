#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'WebService::ForecastIO' ) || print "Bail out!\n";
}

diag( "Testing WebService::ForecastIO $WebService::ForecastIO::VERSION, Perl $], $^X" );
