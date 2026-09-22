package WWW::Hetzner::Role::HTTP;

# ABSTRACT: HTTP client role for Hetzner API clients

use Moo::Role;
use WWW::Hetzner::HTTPRequest;
use WWW::Hetzner::HTTPResponse;
use WWW::Hetzner::LWPIO;
use JSON::MaybeXS qw(decode_json encode_json);
use URI::Escape ();
use Carp qw(croak);
use Log::Any qw($log);

our $VERSION = '0.101';


requires 'token';
requires 'base_url';

has io => (
    is      => 'lazy',
    builder => sub { WWW::Hetzner::LWPIO->new },
);


has sleeper => (
    is      => 'rw',
    default => sub { sub { sleep $_[0] } },
);


sub get {
    my ($self, $path, %params) = @_;
    return $self->_request('GET', $path, %params);
}


sub post {
    my ($self, $path, $data) = @_;
    return $self->_request('POST', $path, body => $data);
}


sub put {
    my ($self, $path, $data) = @_;
    return $self->_request('PUT', $path, body => $data);
}


sub delete {
    my ($self, $path) = @_;
    return $self->_request('DELETE', $path);
}


sub _set_auth {
    my ($self, $headers) = @_;
    $headers->{Authorization} = 'Bearer ' . $self->token;
}


sub _content_type { 'application/json' }


sub _encode_body {
    my ($self, $body) = @_;
    return encode_json($body);
}


sub _build_request {
    my ($self, $method, $path, %opts) = @_;

    my $url = $self->base_url . $path;

    # Add query params for GET
    if ($method eq 'GET' && $opts{params}) {
        my @pairs;
        for my $key (keys %{$opts{params}}) {
            my $value = $opts{params}{$key};
            my @values = ref $value eq 'ARRAY' ? @$value : ($value);
            for my $value (@values) {
                next unless defined $value;
                push @pairs, URI::Escape::uri_escape_utf8($key) . '=' .
                    URI::Escape::uri_escape_utf8($value);
            }
        }
        $url .= '?' . join('&', @pairs) if @pairs;
    }

    $log->debug("$method $url");

    my %headers;
    $self->_set_auth(\%headers);
    $headers{'Content-Type'} = $self->_content_type;

    my %req_args = (
        method  => $method,
        url     => $url,
        headers => \%headers,
    );

    if ($opts{body}) {
        $req_args{content} = $self->_encode_body($opts{body});
        $log->debugf("Body: %s", $req_args{content});
    }

    return WWW::Hetzner::HTTPRequest->new(%req_args);
}


sub _parse_response {
    my ($self, $response, $method, $path) = @_;

    $log->debugf("Response: %s", $response->status);

    my $data;
    if ($response->content && $response->content =~ /^\s*[\{\[]/) {
        $data = decode_json($response->content);
    }

    unless ($response->status >= 200 && $response->status < 300) {
        my $error = $data->{error}{message} // $response->status;
        $log->errorf("API error: %s", $error);
        croak "Hetzner API error: $error";
    }

    $log->infof("%s %s -> %s", $method, $path, $response->status);
    return $data;
}


sub _request {
    my ($self, $method, $path, %opts) = @_;

    croak "No API token configured" unless $self->token;

    my $req = $self->_build_request($method, $path, %opts);
    my $response = $self->io->call($req);
    return $self->_parse_response($response, $method, $path);
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

WWW::Hetzner::Role::HTTP - HTTP client role for Hetzner API clients

=head1 VERSION

version 0.101

=head1 SYNOPSIS

    package WWW::Hetzner::Cloud;
    use Moo;

    has token => ( is => 'ro' );
    has base_url => ( is => 'ro', default => 'https://api.hetzner.cloud/v1' );

    with 'WWW::Hetzner::Role::HTTP';

=head1 DESCRIPTION

This role provides HTTP methods (GET, POST, PUT, DELETE) for Hetzner API
clients. It handles client-specific request-body encoding, JSON response
decoding, authentication, and error handling. Request bodies use JSON by
default; L<WWW::Hetzner::Robot> uses
C<application/x-www-form-urlencoded> instead.

A client with a different body format overrides L</_content_type> and
L</_encode_body>.

HTTP transport is delegated to a pluggable L<WWW::Hetzner::Role::IO> backend
(default: L<WWW::Hetzner::LWPIO>), making it possible to use async HTTP
clients.

Uses L<Log::Any> for logging HTTP requests and responses.

=head1 REQUIRED ATTRIBUTES

Classes consuming this role must provide:

=over 4

=item * C<token> - API authentication token

=item * C<base_url> - Base URL for the API

=back

=head2 io

Pluggable HTTP backend implementing L<WWW::Hetzner::Role::IO>.
Defaults to L<WWW::Hetzner::LWPIO>.

    # Use a custom IO backend
    my $cloud = WWW::Hetzner::Cloud->new(
        token => $token,
        io    => My::AsyncIO->new,
    );

=head2 sleeper

Injectable sleep function, C<sub ($seconds) { ... }>, called with the poll
interval. Defaults to C<sleep>. Declared C<rw> so a test can swap in a
non-blocking counting closure after construction, without rebuilding the
client. Used by L<WWW::Hetzner::Action/wait> between polls, via the
client the action holds a reference to.

=head2 get

    my $data = $self->get('/path', params => { key => 'value' });

Perform a GET request.

=head2 post

    my $data = $self->post('/path', { key => 'value' });

Perform a POST request whose body is encoded by L</_encode_body> with the
media type from L</_content_type>. JSON is the default; the Robot client uses
form encoding.

=head2 put

    my $data = $self->put('/path', { key => 'value' });

Perform a PUT request whose body is encoded by L</_encode_body> with the
media type from L</_content_type>. JSON is the default; the Robot client uses
form encoding.

=head2 delete

    my $data = $self->delete('/path');

Perform a DELETE request.

=head2 _set_auth

Sets authentication headers. Override for different auth mechanisms:

    # Default: Bearer token
    sub _set_auth {
        my ($self, $headers) = @_;
        $headers->{Authorization} = 'Bearer ' . $self->token;
    }

    # Basic Auth (e.g. Robot API)
    sub _set_auth {
        my ($self, $headers) = @_;
        require MIME::Base64;
        $headers->{Authorization} = 'Basic ' .
            MIME::Base64::encode_base64($self->user . ':' . $self->password, '');
    }

=head2 _content_type

Content type for request bodies. The default is C<application/json>.
L<WWW::Hetzner::Robot> overrides this to
C<application/x-www-form-urlencoded>; clients with a different body format
must also override L</_encode_body>.

=head2 _encode_body

Encodes a request body. The default encoder produces JSON. A client that
overrides L</_content_type> for another body format must override this hook to
produce matching content; L<WWW::Hetzner::Robot> uses form encoding.

=head2 _build_request

    my $req = $self->_build_request('GET', '/servers', params => { page => 1 });

Builds a L<WWW::Hetzner::HTTPRequest> without executing it. Useful for
async workflows where request creation and execution are separate steps.

=head2 _parse_response

    my $data = $self->_parse_response($response, 'GET', '/servers');

Parses a L<WWW::Hetzner::HTTPResponse>: decodes JSON, checks for errors.
Useful for async workflows where response parsing happens after transport.

=head1 SEE ALSO

L<WWW::Hetzner::Cloud>, L<WWW::Hetzner::Role::IO>, L<WWW::Hetzner::LWPIO>,
L<WWW::Hetzner::Action>, L<Log::Any>

=head1 SUPPORT

=head2 Issues

Please report bugs and feature requests on GitHub at
L<https://github.com/Getty/p5-www-hetzner/issues>.

=head2 IRC

Join C<#kubernetes> on C<irc.perl.org> or message Getty directly.

=head1 CONTRIBUTING

Contributions are welcome! Please fork the repository and submit a pull request.

=head1 AUTHOR

Torsten Raudssus <torsten@raudssus.de>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2026 by Torsten Raudssus <torsten@raudssus.de> L<https://raudssus.de/>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
