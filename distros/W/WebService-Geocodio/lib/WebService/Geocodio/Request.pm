use strict;
use warnings;

package WebService::Geocodio::Request;
{
  $WebService::Geocodio::Request::VERSION = '0.04';
}

use Moo::Role;
use HTTP::Tiny;
use Carp qw(confess);
use WebService::Geocodio::Location;

with 'WebService::Geocodio::JSON';

# ABSTRACT: A request role for Geocod.io


has 'ua' => (
    is => 'ro',
    lazy => 1,
    default => sub { HTTP::Tiny->new(
        agent => "WebService-Geocodio ",
        default_headers => { 'Content-Type' => 'application/json' },
    ) },
);


has 'base_url' => (
    is => 'ro',
    lazy => 1,
    default => sub { 'http://api.geocod.io/v1/' },
);


sub send_forward {
    my $self = shift;

    $self->_request('geocode', $self->encode(@_));
}


sub send_reverse {
    my $self = shift;

    $self->_request('reverse', $self->encode(@_));
}

sub _request {
    my ($self, $op, $content) = @_;

    my $url;
    if ( $self->has_fields ) {
        $url = $self->base_url 
            . "$op?fields=" . join(',', @{ $self->fields }) 
            .  "&api_key=" . $self->api_key
            ;
    }
    else {
        $url = $self->base_url . "$op?api_key=" . $self->api_key;
    }

    my $response = $self->ua->request('POST', $url, { content => $content });

    if ( $response->{success} ) {
        my $hr = $self->decode($response->{content});
        return map { WebService::Geocodio::Location->new($_) } 
            map {; @{$_->{response}->{results}} } @{$hr->{results}};
    }
    else {
        confess "Request to " . $self->base_url . "$op failed: (" . 
            $response->{status} . ") - " . $response->{content};
    }
}


1;

__END__

=pod

=head1 NAME

WebService::Geocodio::Request - A request role for Geocod.io

=head1 VERSION

version 0.04

=head1 ATTRIBUTES

=head2 ua

A user agent object. Default is L<HTTP::Tiny>

=head2 base_url

The base url to use when connecting to the service. Default is 'http://api.geocod.io'

=head1 METHODS

=head2 send_forward

This method POSTs an arrayref of data to the service for processing.  If the
web call is successful, returns an array of L<WebService::Geocodio::Location>
objects.

Any API errors are fatal and reported by C<Carp::confess>.

=head2 send_reverse

This method POSTs an arrayref of data to the service for processing.  If the
web call is successful, returns an array of L<WebService::Geocodio::Location>
objects.

Any API errors are fatal and reported by C<Carp::confess>.

=head1 AUTHOR

Mark Allen <mrallen1@yahoo.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Mark Allen.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
