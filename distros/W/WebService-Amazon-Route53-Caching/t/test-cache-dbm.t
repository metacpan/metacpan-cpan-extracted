#!/usr/bin/perl -Ilib/ -I../lib/ -w

use strict;
use warnings;

use Test::More qw! no_plan !;
use File::Temp qw/ tempfile /;


BEGIN {use_ok('WebService::Amazon::Route53::Caching::Store::DBM');}
require_ok('WebService::Amazon::Route53::Caching::Store::DBM');


#
#  Create a temporary file to store the has
#
my ( $fh, $file ) = tempfile();
ok( -e $file, "We created a temporary file" );

#
# Delete the file, and create an object
#
unlink($file);
my $cache =
  WebService::Amazon::Route53::Caching::Store::DBM->new( path => $file );

#
# Ensure the object has the correct type.
#
isa_ok( $cache,
        "WebService::Amazon::Route53::Caching::Store::DBM",
        "The cache has the correct type" );

#
#  OK the object is created, but the backing file is missing.
#
#  Setting an object in the cache should create the file
#
ok( !-e $file, "The backing file is absent" );
$cache->set( "steve", "kemp" );
ok( -e $file, "The backing file is created when a value is set" );

#
#  Retrieving the value should work
#
is( $cache->get("steve"), "kemp", "Retrieving a value worked" );

#
#  Now delete the value and ensure the lookup fails
#
$cache->del("steve");
is( $cache->get("steve"), undef,
    "Lookup of a deleted value fails as expected" );

#
#  Cleanup
#
unlink($file) if ( -e $file );
