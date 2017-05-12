#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Test::Proto::Where' ) || print "Bail out!\n";
}

diag( "Testing Test::Proto::Where $Test::Proto::Where::VERSION, Perl $], $^X" );
