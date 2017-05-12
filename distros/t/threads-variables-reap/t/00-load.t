#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'threads::variables::reap' ) || print "Bail out!\n";
}

diag( "Testing threads::variables::reap $threads::variables::reap::VERSION, Perl $], $^X" );
