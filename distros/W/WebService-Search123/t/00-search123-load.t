#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'WebService::Search123' ) || print "Bail out!\n";
}

diag( "Testing WebService::Search123 $WebService::Search123::VERSION, Perl $], $^X" );
