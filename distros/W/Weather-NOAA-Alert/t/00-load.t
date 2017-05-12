#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Weather::NOAA::Alert' ) || print "Bail out!\n";
}

diag( "Testing Weather::NOAA::Alert $Weather::NOAA::Alert::VERSION, Perl $], $^X" );
