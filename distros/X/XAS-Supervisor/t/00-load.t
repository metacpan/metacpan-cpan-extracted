#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'XAS::Supervisor' ) || print "Bail out!\n";
}

diag( "Testing XAS::Supervisor $XAS::Supervisor::VERSION, Perl $], $^X" );
