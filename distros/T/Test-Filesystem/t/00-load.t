#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Test::Filesystem' ) || print "Bail out!\n";
}

diag( "Testing Test::Filesystem $Test::Filesystem::VERSION, Perl $], $^X" );
