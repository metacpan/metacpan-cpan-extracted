#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'CracTools' ) || print "Bail out!\n";
}

diag( "Testing CracTools $CracTools::VERSION, Perl $], $^X" );
