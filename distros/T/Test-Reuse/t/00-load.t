#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Test::Reuse' ) || print "Bail out!\n";
}

diag( "Testing Test::Reuse $Test::Reuse::VERSION, Perl $], $^X" );
