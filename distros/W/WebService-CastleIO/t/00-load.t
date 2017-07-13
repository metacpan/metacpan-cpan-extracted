#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'WebService::CastleIO' ) || print "Bail out!\n";
}

diag( "Testing WebService::CastleIO $WebService::CastleIO::VERSION, Perl $], $^X" );
