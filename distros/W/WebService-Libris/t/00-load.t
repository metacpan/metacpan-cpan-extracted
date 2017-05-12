#!perl

use Test::More tests => 1;

BEGIN {
    use_ok( 'WebService::Libris' ) || print "Bail out!\n";
}

diag( "Testing WebService::Libris $WebService::Libris::VERSION, Perl $], $^X" );
