package WebService::DigitalOcean::Role::UserAgent;
# ABSTRACT: User Agent Role for DigitalOcean WebService
use Moo::Role;
use LWP::UserAgent;
use JSON ();
use DateTime;
use Types::Standard qw/is_HashRef/;
use utf8;

our $VERSION = '0.026'; # VERSION

has ua => (
    is => 'lazy',
);

sub _build_ua {
    my ($self) = @_;

    my $version = __PACKAGE__->VERSION || 'devel';

    my @headers = (
        'Authorization' => 'Bearer ' . $self->token,
        'Content-Type'  => 'application/json; charset=utf-8',
    );

    my $ua = LWP::UserAgent->new(
        agent           => 'WebService::DigitalOcean/' . $version,
        default_headers => HTTP::Headers->new(@headers),
    );

    $ua->env_proxy;

    return $ua;
}

sub _build_request {
    my ( $self, $method, $uri, $data ) = @_;

    my $full_url     = $self->api_base_url . $uri;
    my $encoded_data = $data ? JSON::encode_json($data) : undef;
    my $headers      = undef;

    return HTTP::Request->new( $method, $full_url, $headers, $encoded_data );
}

sub _send_request {
    my ($self, $request) = @_;

    my $response = $self->ua->request($request);

    return $response;
}

sub make_request {
    my ($self, $method, $uri, $data) = @_;

    my $request  = $self->_build_request( $method, $uri, $data );
    my $response = $self->_send_request($request);

    my $result = {
        request_object  => $request,
        response_object => $response,
        is_success      => $response->is_success,
        status_line     => $response->status_line,
    };

    my $ratelimit = $self->_get_ratelimit( $response->headers );

    my $content = $self->_get_content(
        # avoid ``wantarray`` problems by setting scalar context
        my $ct = $response->content_type,
        my $dc = $response->decoded_content,
    );

    return { %$result, %$ratelimit, %$content };
}

sub _get_ratelimit {
    my ($self, $headers) = @_;

    my $limit = $headers->header('RateLimit-Limit');

    if (!$limit) {
        return {};
    }

    return {
        ratelimit => {
            limit     => $limit,
            remaining => $headers->header('RateLimit-Remaining'),
            reset     => DateTime->from_epoch(
                epoch => $headers->header('RateLimit-Reset')
            ),
        }
    };
}

sub _get_content {
    my ($self, $content_type, $content) = @_;

    if ($content_type ne 'application/json') {
        # Delete method returns 'application/octet-stream' according to the API
        # docs, though it is a blank string here. No need to warn on this
        # expected behavior.
        warn "Unexpected Content-Type " . $content_type
            if length $content_type;

        return {};
    }
    else {
        my $decoded_response = JSON::decode_json( $content );

        if ( !is_HashRef($decoded_response) ) {
            return { content => $decoded_response };
        }

        my $meta  = delete $decoded_response->{meta};
        my $links = delete $decoded_response->{links};

        my @values = values %$decoded_response;

        my $c = scalar @values == 1
            ? $values[0]
            : $decoded_response
            ;

        return {
            meta    => $meta,
            links   => $links,
            content => $c,
        };
    }
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

WebService::DigitalOcean::Role::UserAgent - User Agent Role for DigitalOcean WebService

=head1 VERSION

version 0.026

=head1 DESCRIPTION

Role used to make requests to the DigitalOcean API, and to format their response.

=head1 METHODS

=head2 make_request

    my $res = $self->make_request(POST => '/domains', {
        name       => 'example.com',
        ip_address => '12.34.56.78',
    });

=head3 Arguments

=over

=item C<Str> $method

The HTTP verb, such as POST, GET, PUT, etc.

=item C<Str> $path

Path to the resource in the URI, to be prepended with $self->api_base_url.

=item C<HashRef> $data (optional)

The content to be JSON encoded and sent to DigitalOcean's API.

=back

=head3 Returns

HashRef containing:

=over

=item L<HTTP::Response> response_object

=item C<Bool> is_success

Shortcut to $res->{response_object}{is_success}.

=item C<Str> status_line

Shortcut to $res->{response_object}{status_line}.

=item C<HashRef> content

The JSON decoded content the API has responded with.

=item C<HashRef> ratelimit

RateLimit headers parsed.

=over

=item C<Int> limit

=item C<Int> remaining

=item L<DateTime> reset

=back

=back

Makes requests to the DigitalOcean, and parses the response.

All requests made from other methods use L</make_request> to make them.

More info: L<< https://developers.digitalocean.com/#introduction >>.

=head1 AUTHOR

André Walker <andre@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2015 by André Walker.

This is free software, licensed under:

  The GNU General Public License, Version 2, June 1991

=cut
