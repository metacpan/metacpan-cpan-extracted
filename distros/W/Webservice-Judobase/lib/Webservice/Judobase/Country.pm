use strict;
use warnings;

package Webservice::Judobase::Country;
$Webservice::Judobase::Country::VERSION = '0.09';
# ABSTRACT: This module wraps the www.judobase.org website API.
# VERSION

use HTTP::Request;
use JSON::Tiny 'decode_json';
use Moo;

#extends 'Webservice::Judobase';
use namespace::clean;

has 'ua' => (
    is       => 'ro',
    required => 1,
);

has 'url' => (
    is       => 'ro',
    required => 1,
);

sub competitors_list {
    my ( $self, %args ) = @_;
    return { error => 'id_country parameter is required' }
        unless defined $args{id_country};
    return { error => 'id_country parameter must be an integer' }
        unless ( $args{id_country} =~ /\d+/ );

    my $url
        = $self->url
        . '?params[action]=country.competitors_list'
        . '&params[id_country]='
        . $args{id_country};

    my $request  = HTTP::Request->new( GET => $url );
    my $response = $self->ua->request($request);

    if ( $response->code == 200 ) {
        my $data = decode_json $response->content;

        return $data->{competitors};
    }

    return { error => 'Error retreiving country info' };

}

sub get_list {
    my $self = shift;
    my $url  = $self->url . '?params[action]=country.get_list';

    my $request = HTTP::Request->new( GET => $url );

    my $response = $self->ua->request($request);

    if ( $response->code == 200 ) {
        my $data = decode_json $response->content;

        return $data;
    }

    return { error => 'Error retreiving country info' };
}

1;
