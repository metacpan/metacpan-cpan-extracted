#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'VarGuard' ) || print "Bail out!\n";
}

diag( "Testing VarGuard $VarGuard::VERSION, Perl $], $^X" );
