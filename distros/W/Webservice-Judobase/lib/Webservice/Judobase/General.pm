use strict;
use warnings;

package Webservice::Judobase::General;
$Webservice::Judobase::General::VERSION = '0.09';
# VERSION

use Moo;
use HTTP::Request;
use JSON::Tiny 'decode_json';
use LWP::UserAgent;

use namespace::clean;

has 'ua' => (
    is       => 'ro',
    required => 1,
);

has 'url' => (
    is       => 'ro',
    required => 1,
);

sub competition {
    my ( $self, %args ) = @_;
    return { error => 'id parameter is required' } unless defined $args{id};

    my $url
        = $self->url
        . '?params[action]=general.get_one'
        . '&params[module]=competition'
        . '&params[id]='
        . $args{id};

    my $request = HTTP::Request->new( GET => $url );

    my $response = $self->ua->request($request);

    return decode_json $response->content
        if $response->code == 200;

    return { error => 'Error retreiving competitor info' };
}

sub competitions {
    my $self = shift;

    my $url
        = $self->url
        . '?params[action]=competition.get_list'
        . '&params[limit]=9999'
        . '&params[sort]=-1';

    my $request = HTTP::Request->new( GET => $url );

    my $response = $self->ua->request($request);

    return decode_json $response->content
        if $response->code == 200;

    return { error => 'Error retreiving competitions info' };
}

sub competitors {
    my ( $self, %args ) = @_;
    return { error => 'event_id parameter is required' }
        unless defined $args{event_id};

    my $url
        = $self->url
        . '?params[action]=competition.competitors'
        . '&params[id_competition]='
        . $args{event_id};

    my $request = HTTP::Request->new( GET => $url );

    my $response = $self->ua->request($request);

    my @competitors = ();
    if ( $response->code == 200 ) {
        my $info = decode_json $response->content;

        for my $gender ( values %{ $info->{categories} } ) {
            for my $cat ( values %$gender ) {
                for my $person ( values %{ $cat->{persons} } ) {
                    push @competitors, $person;
                }
            }
        }

        return \@competitors;
    }
    else {
        return { error => 'Error retreiving competitors info' };
    }
}

1;
