#!/usr/bin/perl -w

use strict;
use warnings;

use Test::More tests => 28;

use WebService::StreetMapLink;

use URI;
use URI::QueryParam;

{
    my $map = WebService::StreetMapLink->new( country => 'usa',
                                              address => '100 Some Street',
                                              city    => 'Testville',
                                              state   => 'MN',
                                              postal_code => '12345',
                                              subclass => 'MapQuest',
                                            );

    is( $map->service_name, 'MapQuest', 'service_name is MapQuest' );

    my $uri = $map->uri;

    ok( $uri, 'some sort of url was generated' );

    my $obj = $map->uri_object;

    is( $obj->scheme, 'http', 'URL scheme is http' );

    is( $obj->host, 'www.mapquest.com', 'URL host is www.mapquest.com' );

    is( $obj->path, '/maps/map.adp', 'URL path is /maps/map.adp' );

    my %expect = ( address  => '100 Some Street',
                   city     => 'Testville',
                   state    => 'MN',
                   zip      => '12345',
                   country   => 'US',
                   countryid => 'US',
                   zoom     => 8,
                 );
    while ( my ( $k, $v ) = each %expect )
    {
        is( $obj->query_param($k), $v, "URL query param $k should be $v" );
    }
}

{
    my $map = WebService::StreetMapLink->new( country => 'canada',
                                              address => '500 Big Ave',
                                              city    => 'Oot',
                                              state   => 'Quebec',
                                              postal_code => '5B1 A9Q',
                                              subclass => 'MapQuest',
                                            );

    my $uri = $map->uri;

    ok( $uri, 'some sort of url was generated' );

    my $obj = $map->uri_object;

    is( $obj->scheme, 'http', 'URL scheme is http' );

    is( $obj->host, 'www.mapquest.com', 'URL host is www.mapquest.com' );

    is( $obj->path, '/maps/map.adp', 'URL path is /maps/map.adp' );

    my %expect = ( address  => '100 Some Street',
                   address   => '500 Big Ave',
                   city      => 'Oot',
                   state     => 'QC',
                   zip       => '5B1 A9Q',
                   country   => 'CA',
                   countryid => 41,
                   zoom      => 8,
                 );
    while ( my ( $k, $v ) = each %expect )
    {
        is( $obj->query_param($k), $v, "URL query param $k should be $v" );
    }
}

{
    my $map = WebService::StreetMapLink->new( country => 'canada',
                                              address => "500 L'Hôtel Ave",
                                              city    => 'Oot',
                                              state   => 'Québec',
                                              postal_code => '5B1 A9Q',
                                              subclass => 'MapQuest',
                           );

    my $uri = $map->uri;

    ok( $uri, 'some sort of url was generated' );

    my $obj = $map->uri_object;

    is( $obj->query_param('state'), 'QC', "Make sure accents are stripped from data" );

    is( $obj->query_param('address'), "500 L'Hotel Ave", "Make sure accents are stripped from data" );
}

{
    my $map = WebService::StreetMapLink->new( country => 'usa',
                                              address => '100 Some Street',
                                              city    => 'Testville',
                                              state   => 'MN',
                                              postal_code => '12345',
                                              zoom    => 4,
                                              subclass => 'MapQuest',
                                            );

    my $uri = $map->uri;

    ok( $uri, 'some sort of url was generated' );

    my $obj = $map->uri_object;

    is( $obj->query_param('zoom'), 4, "URL query param zoom should be 4" );
}
