use 5.014;

package WebService::ForecastIO::Request;
$WebService::ForecastIO::Request::VERSION = '0.02';
use Moo::Role;
use HTTP::Tiny;
use JSON;

# ABSTRACT: Request role for WebService::ForecaseIO


has 'base_url' => (
    is => 'ro',
    default => sub { "https://api.darksky.net/forecast" },
);

has 'api_key' => (
    is => 'ro',
    required => 1
);


has 'ua' => (
    is => 'ro',
    default => sub {
        HTTP::Tiny->new(
            agent => "WebService::ForecastIO/$WebService::ForecastIO::VERSION ",
            SSL_options => {
                SSL_hostname => "",
                SSL_verify_mode => 0
            },
        );
    },
    lazy => 1,
);


has 'decoder' => (
    is => 'ro',
    default => sub {
        JSON->new();
    },
    lazy => 1,
);

sub request {
    my $self = shift;

    my $url = $self->base_url . "/" . $self->api_key . "/" . (join ",", @_);

    my $qp = join "&", (map {; "$_=" . $self->$_() } 
                        grep {; defined $self->$_() } qw(exclude units));

    if ( $qp ) {
        $url .= "?$qp";
    }

    my $response = $self->ua->get($url);

    if ( $response->{success} ) {
        $self->decoder->decode($response->{content});
    }
    else {
        die "Request to $url returned $response->{status}: $response->{content}\n";
    }
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

WebService::ForecastIO::Request - Request role for WebService::ForecaseIO

=head1 VERSION

version 0.02

=head1 OVERVIEW

This is a role which implements requests to the L<forecast.io> API.

=head1 ATTRIBUTES

=head2 base_url

The base url to connect to the web service. Defaults to L<https://api.forecast.io/forecast>

=head2 ua

The user agent for the role. Uses L<HTTP::Tiny>.

=head2 decoder

The library to deserialize JSON responses. Uses L<JSON>.

=head1 AUTHOR

Mark Allen <mrallen1@yahoo.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Mark Allen.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
