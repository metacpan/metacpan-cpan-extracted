#!perl
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'WebService::IdoitAPI' ) || print "Bail out!\n";
}

diag( "Testing WebService::IdoitAPI $WebService::IdoitAPI::VERSION, Perl $], $^X" );
