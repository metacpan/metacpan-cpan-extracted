# NAME

Yandex::Geo - Performs queries using Yandex Maps Company Search API

# VERSION

version 0.07

# DESCRIPTION

Implements Yandex Maps Company Search API 

[https://tech.yandex.ru/maps/geosearch/](https://tech.yandex.ru/maps/geosearch/)

# NAME

Yandex::Geo

# SYNOPSYS

    use Yandex::Geo;
    
    my $yndx_geo = Yandex::Geo->new(
        apikey => 'f33a4523-6c94-48df-9b41-5c5c6f250e98',
        only_city => 'ROV',
        results => 20
    );
    
    my $geo_json = $yndx_geo->get(text => 'autoservice', type => 'biz');
    
    my $res = $yndx_geo->y_companies('autoservice', only_city => 'MSK');

# SEE ALSO

[Geo::Yandex](https://metacpan.org/pod/Geo::Yandex)

# METHODS

## cities\_bbox

    $self->cities_bbox();
    Yandex::Geo::cities_bbox();

Return hash of approximate big cities borders

Each border is geo coordinates in format: left bottom corner (longitude, latitude) - top right corner (longitude, latitude)

E.g for Rostov-on-Don is `39.535873,47.146130~39.842460,47.35675'`

## new

Constructor

Required parameter: apikey

To use in every request you can provide same parameters as in ["get" in Yandex::Geo](https://metacpan.org/pod/Yandex::Geo#get), except text parameter

## get

Perform API request, handle http errors and return [Geo::JSON::FeatureCollection](https://metacpan.org/pod/Geo::JSON::FeatureCollection) object

Implements all parameters from [https://tech.yandex.ru/maps/doc/geosearch/concepts/request-docpage/](https://tech.yandex.ru/maps/doc/geosearch/concepts/request-docpage/)

In addition to standart params it implement city param. Check more about its usage and cities available at ["cities\_bbox" in Yandex::Geo](https://metacpan.org/pod/Yandex::Geo#cities_bbox)

    $yndx_geo->get(text => 'макетные мастерские', city => 'ROV');  # Geo::JSON::FeatureCollection

If you need to get plain json instead of just [Geo::JSON::FeatureCollection](https://metacpan.org/pod/Geo::JSON::FeatureCollection) simply add `to_json` method to chain:

    $yndx_geo->get(text => 'макетные мастерские', city => 'ROV')->to_json;

## y\_companies

Do same as ["get" in Yandex::Geo](https://metacpan.org/pod/Yandex::Geo#get) but return array of [Yandex::Geo::Companies](https://metacpan.org/pod/Yandex::Geo::Companies) objects

For convenience, search text is provided as first parametes

    $yndx_geo->y_companies('макетные мастерские', city => 'ROV', results => '500');  # Geo::JSON::FeatureCollection

# AUTHOR

Pavel Serikov <pavelsr@cpan.org>

# COPYRIGHT AND LICENSE

This software is copyright (c) 2018 by Pavel Serikov.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.
