#!/usr/bin/perl -w

use strict;
use warnings;

use Test::More tests => 26;

use WebService::StreetMapLink;

use URI;
use URI::QueryParam;

{
    my %p = ( country => 'usa',
              address => '100 Some Street',
              city    => 'Testville',
              state   => 'MN',
              postal_code => '12345',
            );

    my $map = WebService::StreetMapLink->new(%p);

    is( $map->service_name, 'Google Maps', 'service_name is Google Maps' );

    my $uri = $map->uri;

    ok( $uri, 'some sort of url was generated' );

    my $obj = $map->uri_object;

    is( $obj->scheme, 'http', 'URL scheme is http' );

    is( $obj->host, 'maps.google.com', 'URL host is maps.google.com' );

    is( $obj->path, '/maps', 'URL path is /maps' );

    my %expect = ( q => join ',', map { $p{$_} } qw( address city state postal_code country ) );

    while ( my ( $k, $v ) = each %expect )
    {
        is( $obj->query_param($k), $v, "URL query param $k should be $v" );
    }
}

{
    my %p = ( country => 'usa',
              address => '100 Some Street',
              city    => 'Testville',
              state   => 'MN',
              postal_code => '12345-9876',
            );

    my $map = WebService::StreetMapLink->new(%p);

    my $uri = $map->uri;

    ok( $uri, 'some sort of url was generated' );

    my $obj = $map->uri_object;

    is( $obj->scheme, 'http', 'URL scheme is http' );

    is( $obj->host, 'maps.google.com', 'URL host is maps.google.com' );

    is( $obj->path, '/maps', 'URL path is /maps' );

    my %expect = ( q => join ',', ( map { $p{$_} } qw( address city state ) ),
                                  '12345', $p{country} );

    while ( my ( $k, $v ) = each %expect )
    {
        is( $obj->query_param($k), $v, "URL query param $k should be $v" );
    }
}

{
    my %p = ( country => 'uk',
              address => '100 Some Street',
              city    => 'London',
              postal_code => 'W1U 5HN',
            );

    my $map = WebService::StreetMapLink->new(%p);

    my $uri = $map->uri;

    ok( $uri, 'some sort of url was generated' );

    my $obj = $map->uri_object;

    is( $obj->scheme, 'http', 'URL scheme is http' );

    is( $obj->host, 'maps.google.com', 'URL host is maps.google.com' );

    is( $obj->path, '/maps', 'URL path is /maps' );

    my %expect = ( q => join ',', map { $p{$_} } qw( address city postal_code country ) );

    while ( my ( $k, $v ) = each %expect )
    {
        is( $obj->query_param($k), $v, "URL query param $k should be $v" );
    }
}

{
    my %p = ( country => 'australia',
              address => '606 Station Street',
              city    => 'Box Hill',
              state   => 'Victoria',
              postal_code => '3128',
            );

    my $map = WebService::StreetMapLink->new(%p);

    my $uri = $map->uri;

    ok( $uri, 'some sort of url was generated' );

    my $obj = $map->uri_object;

    is( $obj->scheme, 'http', 'URL scheme is http' );

    is( $obj->host, 'maps.google.com', 'URL host is maps.google.com' );

    is( $obj->path, '/maps', 'URL path is /maps' );


    my %expect = ( q => join ',', map { $p{$_} } qw( address city state postal_code country ) );

    while ( my ( $k, $v ) = each %expect )
    {
        is( $obj->query_param($k), $v, "URL query param $k should be $v" );
    }
}

{
    my %p = ( country => 'switzerland',
              address => 'rue de Paquis 25',
              city    => 'Geneva',
              state   => 'Geneve',
              postal_code => '1201',
            );

    my $map = WebService::StreetMapLink->new(%p);

    my $uri = $map->uri;

    ok( $uri, 'some sort of url was generated' );

    my $obj = $map->uri_object;

    is( $obj->scheme, 'http', 'URL scheme is http' );

    is( $obj->host, 'maps.google.com', 'URL host is maps.google.com' );

    is( $obj->path, '/maps', 'URL path is /maps' );


    my %expect = ( q => join ',', map { $p{$_} } qw( address city state postal_code country ) );

    while ( my ( $k, $v ) = each %expect )
    {
        is( $obj->query_param($k), $v, "URL query param $k should be $v" );
    }
}
