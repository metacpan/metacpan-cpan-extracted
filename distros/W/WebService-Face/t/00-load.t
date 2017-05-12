#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'WebService::Face::Client' ) || print "Bail out!\n";
}

diag( "Testing WebService::Face::Client $WebService::Face::Client::VERSION, Perl $], $^X" );
