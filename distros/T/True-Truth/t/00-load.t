#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'True::Truth' ) || print "Bail out!\n";
}

diag( "Testing True::Truth $True::Truth::VERSION, Perl $], $^X" );
