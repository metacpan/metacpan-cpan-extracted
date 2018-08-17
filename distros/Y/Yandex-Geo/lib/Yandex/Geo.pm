# ABSTRACT: Performs queries using Yandex Maps Company Search API

package Yandex::Geo;
$Yandex::Geo::VERSION = '0.07';
use strict;
use warnings;


use LWP::UserAgent;
use URI;
use URI::Escape;
use Geo::JSON;
use Carp;
use utf8;

use Yandex::Geo::Company;


sub cities_bbox {
    return { 'ROV' => '39.535873,47.146130~39.842460,47.356752' };
}


sub new {
    my ( $class, %params ) = @_;

    confess 'Empty apikey'
      unless defined $params{apikey} && length $params{apikey};

    my $self = {
        ua       => LWP::UserAgent->new( timeout => 10 ),
        base_url => 'https://search-maps.yandex.ru/v1/',
        %params,
    };

    bless $self, $class;
}


sub get {
    my ( $self, %params ) = @_;

    my $url_params = $self->_build_params(%params);
    my $url        = URI->new( $self->{base_url} );
    $url->query_form($url_params);

    my $response = $self->{ua}->get($url);

    unless ( $response->is_success ) {
        if ( int( $response->code / 100 ) == 4 ) {
            die $response->status_line . ': ' . $response->decoded_content;
        }

        die $response->status_line;
    }

    Geo::JSON->from_json( $response->decoded_content );

}


sub y_companies {
    my ( $self, $text, %params ) = @_;

    my $geo_json = $self->get( text => $text, %params );
    Yandex::Geo::Company::from_geo_json($geo_json);
}

sub _build_params {
    my ( $self, %params ) = @_;

    # Set default parameters

    confess 'No search text provided'
      unless defined $params{text} && length $params{text};

    my $mess = {
        apikey => $self->{apikey},
        text   => $params{text},
        type   => $self->{type} || $params{type} || 'biz',
        lang   => $self->{lang} || $params{lang} || 'ru_RU',
        ll      => $self->{ll}      || $params{ll},
        spn     => $self->{spn}     || $params{spn},
        bbox    => $self->{bbox}    || $params{bbox},
        rspn    => $self->{rspn}    || $params{rspn} || 1,
        results => $self->{results} || $params{results} || 25,
        skip    => $self->{skip}    || $params{skip}
    };

    $mess->{bbox} = $self->cities_bbox->{ $self->{only_city} }
      if defined $self->{only_city};
    $mess->{bbox} = $self->cities_bbox->{ $params{only_city} }
      if defined $params{only_city};

    # Remove empty params to not overload query

    for my $k ( keys %$mess ) {
        delete $mess->{$k} unless $mess->{$k};
    }

    delete $mess->{only_city};

    return $mess;

}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Yandex::Geo - Performs queries using Yandex Maps Company Search API

=head1 VERSION

version 0.07

=head1 DESCRIPTION

Implements Yandex Maps Company Search API 

L<https://tech.yandex.ru/maps/geosearch/>

=head1 NAME

Yandex::Geo

=head1 SYNOPSYS

    use Yandex::Geo;
    
    my $yndx_geo = Yandex::Geo->new(
        apikey => 'f33a4523-6c94-48df-9b41-5c5c6f250e98',
        only_city => 'ROV',
        results => 20
    );
    
    my $geo_json = $yndx_geo->get(text => 'autoservice', type => 'biz');
    
    my $res = $yndx_geo->y_companies('autoservice', only_city => 'MSK');

=head1 SEE ALSO

L<Geo::Yandex>

=head1 METHODS

=head2 cities_bbox

    $self->cities_bbox();
    Yandex::Geo::cities_bbox();

Return hash of approximate big cities borders

Each border is geo coordinates in format: left bottom corner (longitude, latitude) - top right corner (longitude, latitude)

E.g for Rostov-on-Don is C<39.535873,47.146130~39.842460,47.35675'>

=head2 new

Constructor

Required parameter: apikey

To use in every request you can provide same parameters as in L<Yandex::Geo/get>, except text parameter

=head2 get

Perform API request, handle http errors and return L<Geo::JSON::FeatureCollection> object

Implements all parameters from L<https://tech.yandex.ru/maps/doc/geosearch/concepts/request-docpage/>

In addition to standart params it implement city param. Check more about its usage and cities available at L<Yandex::Geo/cities_bbox>

    $yndx_geo->get(text => 'макетные мастерские', city => 'ROV');  # Geo::JSON::FeatureCollection

If you need to get plain json instead of just L<Geo::JSON::FeatureCollection> simply add C<to_json> method to chain:

    $yndx_geo->get(text => 'макетные мастерские', city => 'ROV')->to_json;

=head2 y_companies

Do same as L<Yandex::Geo/get> but return array of L<Yandex::Geo::Companies> objects

For convenience, search text is provided as first parametes

    $yndx_geo->y_companies('макетные мастерские', city => 'ROV', results => '500');  # Geo::JSON::FeatureCollection

=head1 AUTHOR

Pavel Serikov <pavelsr@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018 by Pavel Serikov.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
