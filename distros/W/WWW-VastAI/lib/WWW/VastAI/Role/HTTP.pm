package WWW::VastAI::Role::HTTP;
our $VERSION = '0.001';
# ABSTRACT: Shared synchronous HTTP client role for Vast.ai API consumers

use Moo::Role;
use Carp qw(croak);
use JSON::MaybeXS qw(decode_json encode_json);
use Log::Any qw($log);
use URI;
use WWW::VastAI::HTTPRequest;
use WWW::VastAI::LWPIO;

requires 'api_key';
requires 'base_url';

has io => (
    is      => 'lazy',
    builder => sub { WWW::VastAI::LWPIO->new },
);

sub get {
    my ($self, $path, %opts) = @_;
    return $self->_request('GET', $path, %opts);
}

sub post {
    my ($self, $path, $body, %opts) = @_;
    return $self->_request('POST', $path, %opts, body => $body);
}

sub put {
    my ($self, $path, $body, %opts) = @_;
    return $self->_request('PUT', $path, %opts, body => $body);
}

sub delete {
    my ($self, $path, $body, %opts) = @_;
    return $self->_request('DELETE', $path, %opts, (defined $body ? (body => $body) : ()));
}

sub _set_auth {
    my ($self, $headers) = @_;
    $headers->{Authorization} = 'Bearer ' . $self->api_key;
}

sub _build_query_uri {
    my ($self, $url, $params) = @_;

    my $uri = URI->new($url);
    for my $name (sort keys %{$params || {}}) {
        my $value = $params->{$name};
        next unless defined $value;
        $value = encode_json($value) if ref $value;
        $uri->query_param($name => $value);
    }

    return $uri->as_string;
}

sub _build_request {
    my ($self, $method, $path, %opts) = @_;

    my $base_url = $opts{base_url} || $self->base_url;
    my $url = $base_url . $path;
    $url = $self->_build_query_uri($url, $opts{params}) if $opts{params};

    my %headers = (
        'Content-Type' => 'application/json',
    );
    $self->_set_auth(\%headers);

    my %args = (
        method  => $method,
        url     => $url,
        headers => \%headers,
    );

    if (exists $opts{body}) {
        $args{content} = encode_json($opts{body});
        $log->debugf('%s %s body=%s', $method, $url, $args{content});
    }
    else {
        $log->debugf('%s %s', $method, $url);
    }

    return WWW::VastAI::HTTPRequest->new(%args);
}

sub _parse_response {
    my ($self, $response, $method, $path) = @_;

    my $content = $response->content;
    my $data;
    if (defined $content && $content =~ /^\s*[\{\[]/) {
        $data = decode_json($content);
    }
    elsif (defined $content && length $content) {
        $data = $content;
    }

    if ($response->status < 200 || $response->status >= 300) {
        my $message = ref $data eq 'HASH'
            ? ($data->{msg} || $data->{message} || $data->{error} || $response->status)
            : (defined $data ? $data : $response->status);
        croak "Vast.ai API error: $message";
    }

    $log->infof('%s %s -> %s', $method, $path, $response->status);
    return $data;
}

sub _request {
    my ($self, $method, $path, %opts) = @_;

    croak "No Vast.ai API key configured" unless $self->api_key;

    my $req = $self->_build_request($method, $path, %opts);
    my $response = $self->io->call($req);
    return $self->_parse_response($response, $method, $path);
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

WWW::VastAI::Role::HTTP - Shared synchronous HTTP client role for Vast.ai API consumers

=head1 VERSION

version 0.001

=head1 DESCRIPTION

This role provides the low-level HTTP functionality used by L<WWW::VastAI>.
It handles bearer authentication, JSON encoding/decoding, pluggable IO
backends, and uniform error handling.

=head1 REQUIRED ATTRIBUTES

=over 4

=item * C<api_key>

=item * C<base_url>

=back

=head1 METHODS

=head2 get

    my $data = $client->get('/instances/');

Performs a GET request.

=head2 post

    my $data = $client->post('/bundles/', \%body);

Performs a POST request with a JSON body.

=head2 put

    my $data = $client->put('/instances/123/', \%body);

Performs a PUT request with a JSON body.

=head2 delete

    my $data = $client->delete('/instances/123/');
    my $data = $client->delete('/template/', { id => 123 });

Performs a DELETE request. Vast.ai uses both path-only and JSON-body delete
styles, so an optional body is supported.

=head1 SEE ALSO

L<WWW::VastAI>, L<WWW::VastAI::Role::IO>, L<WWW::VastAI::LWPIO>

=head1 SUPPORT

=head2 Issues

Please report bugs and feature requests on GitHub at
L<https://github.com/Getty/p5-www-vastai/issues>.

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
