#!perl -T
use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'WebService::Ooyala' ) || print "Bail out!\n";
}

diag( "Testing WebService::Ooyala $WebService::Ooyala::VERSION, Perl $], $^X" );
