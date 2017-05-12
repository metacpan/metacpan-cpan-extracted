#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Try::Tiny::SmartCatch' ) || print "Bail out!\n";
}

diag( "Testing Try::Tiny::SmartCatch $Try::Tiny::SmartCatch::VERSION, Perl $], $^X" );
