#!perl

use Test::More tests => 1;

BEGIN {
    use_ok( 'Worlogog::Incident' );
}

diag( "Testing Worlogog::Incident $Worlogog::Incident::VERSION, Perl $], $^X" );
