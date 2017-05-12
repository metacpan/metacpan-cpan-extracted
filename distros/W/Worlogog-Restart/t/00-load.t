#!perl

use Test::More tests => 1;

BEGIN {
    use_ok( 'Worlogog::Restart' );
}

diag( "Testing Worlogog::Restart $Worlogog::Restart::VERSION, Perl $], $^X" );
