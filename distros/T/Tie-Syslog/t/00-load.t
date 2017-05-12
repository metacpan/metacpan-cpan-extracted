#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Tie::Syslog' ) || print "Bail out!\n";
}

diag( "Testing Tie::Syslog $Tie::Syslog::VERSION, Perl $], $^X" );
