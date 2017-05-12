#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Twitter::Badge' ) || print "Bail out!\n";
}

diag( "Testing Twitter::Badge $Twitter::Badge::VERSION, Perl $], $^X" );
