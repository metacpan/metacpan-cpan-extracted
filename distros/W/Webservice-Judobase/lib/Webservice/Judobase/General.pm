package Webservice::Judobase::General;

use strict;
use warnings;

our $VERSION = '0.003'; # VERSION

use Moo;
use HTTP::Request;
use JSON::Tiny 'decode_json';
use LWP::UserAgent;

use namespace::clean;

has 'url' => (
    is      => 'ro',
    default => 'http://data.judobase.org/api/get_json',
);

sub competition {
    my ( $self, %args ) = @_;
    return { error => 'id parameter is required' } unless defined $args{id};

    my $url =
        $self->url
      . '?params[action]=general.get_one'
      . '&params[module]=competition'
      . '&params[id]='
      . $args{id};

    my $ua = LWP::UserAgent->new;
    my $request = HTTP::Request->new( GET => $url );

    my $response = $ua->request($request);

    return decode_json $response->content
      if $response->code == 200;

    return { error => 'Error retreiving competitor info' };
}

1;
