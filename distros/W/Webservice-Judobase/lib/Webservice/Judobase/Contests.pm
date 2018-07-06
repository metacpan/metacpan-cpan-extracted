package Webservice::Judobase::Contests;

use strict;
use warnings;

our $VERSION = '0.002'; # VERSION

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
    return { error => 'id parameter is required' }
      unless defined $args{id};

    my $url =
        $self->url
      . '?params[action]=contest.find'
      . '&params[id_weight]=0'
      . '&params[order_by]=cnum'
      . '&params[id_competition]='
      . $args{id};

    my $ua = LWP::UserAgent->new;
    my $request = HTTP::Request->new( GET => $url );

    my $response = $ua->request($request);

    return decode_json( $response->content )->{contests}
      if $response->code == 200;

    return { error => 'Error retreiving competitor info' };
}

1;
