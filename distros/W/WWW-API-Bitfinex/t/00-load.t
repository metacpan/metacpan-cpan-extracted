#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'WWW::API::Bitfinex' ) || print "Bail out!\n";
}

diag( "Testing WWW::API::Bitfinex $WWW::API::Bitfinex::VERSION, Perl $], $^X" );
