#!perl -T
use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'WebService::GarminConnect' ) || print "Bail out!\n";
}

diag( "Testing WebService::GarminConnect $WebService::GarminConnect::VERSION, Perl $], $^X" );
