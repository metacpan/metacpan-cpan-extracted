#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'pantheon' ) || print "Bail out!\n";
}

diag( "Testing pantheon $pantheon::VERSION, Perl $], $^X" );
