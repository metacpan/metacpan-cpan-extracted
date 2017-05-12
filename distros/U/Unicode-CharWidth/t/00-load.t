#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Unicode::CharWidth' ) || print "Bail out!\n";
}

diag( "Testing Unicode::CharWidth $Unicode::CharWidth::VERSION, Perl $], $^X" );
