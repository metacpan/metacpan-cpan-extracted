#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'URI::di' ) || print "Bail out!\n";
}

diag( "Testing URI::di $URI::di::VERSION, Perl $], $^X" );
