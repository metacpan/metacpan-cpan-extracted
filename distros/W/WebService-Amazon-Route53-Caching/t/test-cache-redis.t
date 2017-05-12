#!/usr/bin/perl -Ilib/ -I../lib/ -w

use strict;
use warnings;

use Test::More qw! no_plan !;


BEGIN {use_ok('WebService::Amazon::Route53::Caching::Store::Redis');}
require_ok('WebService::Amazon::Route53::Caching::Store::Redis');


#
#  Should we skip these tests?
#
my $skip = 0;


#
#  Ensure that we have Redis installed.
#
## no critic (Eval)
eval "use Redis";
## use critic
$skip = 1 if ($@);


#
# Connect to redis
#
my $redis;
eval {$redis = new Redis();};
$skip = 1 if ($@);
$skip = 1 unless ($redis);
$skip = 1 unless ( $redis && $redis->ping() );


SKIP:
{
    skip "Redis must be running on localhost" unless ( !$skip );


    my $cache =
      WebService::Amazon::Route53::Caching::Store::Redis->new(
                                                              redis => $redis );

    #
    # Ensure the object has the correct type.
    #
    isa_ok( $cache,
            "WebService::Amazon::Route53::Caching::Store::Redis",
            "The cache has the correct type" );


    #
    #  Try to set a value
    #
    $cache->set( "steve", "kemp" );
    is( $cache->get("steve"), "kemp", "Storing a value worked " );

    #
    # Now delete that value
    #
    $cache->del("steve");
    is( $cache->get("steve"), undef, "Storing a value worked " );

}

