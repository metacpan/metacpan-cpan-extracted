#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'threads::variables::reap::attr' ) || print "Bail out!\n";
}

diag( "Testing threads::variables::reap::attr $threads::variables::reap::attr::VERSION, Perl $], $^X" );
