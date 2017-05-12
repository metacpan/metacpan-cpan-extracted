#!/usr/bin/perl -Ilib/ -I../lib/ -w

use strict;
use warnings;

use Test::More qw! no_plan !;


BEGIN {use_ok('WebService::Amazon::Route53::Caching::Store::NOP');}
require_ok('WebService::Amazon::Route53::Caching::Store::NOP');


#
#  Create the object.
#
my $cache = WebService::Amazon::Route53::Caching::Store::NOP->new();

#
#  Ensure it is of the right type
#
isa_ok( $cache,
        "WebService::Amazon::Route53::Caching::Store::NOP",
        "The cache has the correct type" );


#
#  Ensure all expected methods are present
#
foreach my $method (qw! get set del !)
{
    ok( UNIVERSAL::can( $cache, $method ),
        "The expected method is present $method" );
}
