use strict;
use warnings;

package Webservice::Judobase::Competitor;
$Webservice::Judobase::Competitor::VERSION = '0.07';
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

sub best_results {
    my ( $self, %args ) = @_;
    return { error => 'id parameter is required' } unless defined $args{id};

    my $url
        = $self->url
        . '?params[action]=competitor.best_results&params[id_person]='
        . $args{id};

    my $request = HTTP::Request->new( GET => $url );

    my $response = $self->ua->request($request);

    return decode_json $response->content
        if $response->code == 200;

    return { error => 'Error retreiving competitor info' };
}

sub birthdays_competitors {
    my ( $self, %args ) = @_;

    return { error => 'min_age parameter is required' }
        unless defined $args{min_age};
    my $url
        = $self->url
        . '?params[action]=competitor.birthday_competitors&params[min_age]='
        . $args{min_age};

    my $request = HTTP::Request->new( GET => $url );

    my $response = $self->ua->request($request);

    return decode_json $response->content
        if $response->code == 200;

    return { error => 'Error retreiving competitor info' };
}

sub contests {
    my ( $self, %args ) = @_;

    return { error => 'id parameter is required' } unless defined $args{id};
    my $url
        = $self->url
        . '?params[action]=competitor.contests&params[id_person]='
        . $args{id};

    my $request = HTTP::Request->new( GET => $url );

    my $response = $self->ua->request($request);

    return decode_json $response->content
        if $response->code == 200;

    return { error => 'Error retreiving competitor info' };

}

sub contests_statistics {
    my ( $self, %args ) = @_;

    return { error => 'id parameter is required' } unless defined $args{id};
    my $url
        = $self->url
        . '?params[action]=competitor.contests_statistics&params[id_person]='
        . $args{id};

    my $request = HTTP::Request->new( GET => $url );

    my $response = $self->ua->request($request);

    return decode_json $response->content
        if $response->code == 200;

    return { error => 'Error retreiving competitor contests statistics' };

}

sub fights_statistics {
    my ( $self, %args ) = @_;

    return { error => 'id parameter is required' } unless defined $args{id};

    my $url
        = $self->url
        . '?params[action]=competitor.fights_statistics&params[id_person]='
        . $args{id};

    my $request = HTTP::Request->new( GET => $url );

    my $response = $self->ua->request($request);

    if ( $response->code == 200 ) {
        my $data = decode_json $response->content;

        return $data->[0] if ref $data eq 'ARRAY';
        return $data;
    }

    return { error => 'Error retreiving competitor info' };
}

sub info {
    my ( $self, %args ) = @_;

    return { error => 'id parameter is required' } unless defined $args{id};

    my $url
        = $self->url
        . '?params[action]=competitor.info&params[id_person]='
        . $args{id};

    my $request = HTTP::Request->new( GET => $url );

    my $response = $self->ua->request($request);

    return decode_json $response->content
        if $response->code == 200;

    return { error => 'Error retreiving competitor info' };
}

sub wrl_current {
    my ( $self, %args ) = @_;

    return { error => 'id parameter is required' } unless defined $args{id};

    my $url
        = $self->url
        . '?params[action]=competitor.wrl_current&params[id_person]='
        . $args{id};

    my $request = HTTP::Request->new( GET => $url );

    my $response = $self->ua->request($request);

    if ( $response->code == 200 ) {
        my $data = decode_json $response->content;

        return $data->[0] if ref $data eq 'ARRAY';
        return $data;
    }

    return { error => 'Error retreiving competitor info' };
}

1;
