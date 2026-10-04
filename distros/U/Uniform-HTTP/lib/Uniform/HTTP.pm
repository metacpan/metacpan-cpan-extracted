package Uniform::HTTP;

use strict;
use warnings;

our $VERSION = '0.04';

1;

__END__

=head1 NAME

Uniform::HTTP - Framework-neutral HTTP messages and authentication

=head1 SYNOPSIS

    use Uniform::HTTP::Request;
    use Uniform::HTTP::Response;

    my $request = Uniform::HTTP::Request->new(
        method    => 'GET',
        target    => '/users?id=42',
        scheme    => 'https',
        authority => 'example.com',
    );

    my $response = Uniform::HTTP::Response->new(
        status => 200,
        body   => "hello\n",
    );

=head1 DESCRIPTION

Uniform::HTTP provides small HTTP message objects that are not tied to one
client, server, framework, transport, or event loop.

It gives HTTP implementations a common way to represent requests, responses,
headers, trailers, buffered bodies, and authentication data across HTTP/1,
HTTP/2, and HTTP/3.

Uniform::HTTP does not open sockets, parse network traffic, serialize HTTP, or
send requests. The surrounding HTTP implementation still owns those jobs.

=head1 START HERE

Most application code uses L<Uniform::HTTP::Request> and
L<Uniform::HTTP::Response>.

A request needs a method and target:

    my $request = Uniform::HTTP::Request->new(
        method => 'GET',
        target => '/items',
    );

A response needs a status:

    my $response = Uniform::HTTP::Response->new(
        status => 200,
        body   => 'ok',
    );

Headers are stored as ordered name/value pairs so duplicate fields are not
lost:

    my $response = Uniform::HTTP::Response->new(
        status => 200,
        headers => [
            [ 'Set-Cookie', 'a=1' ],
            [ 'Set-Cookie', 'b=2' ],
        ],
    );

    my $values = $response->header_values('Set-Cookie');

C<body()> only returns a body that is already buffered. It never consumes a
stream or performs I/O.

=head1 TRAILERS AND INCREMENTAL MESSAGES

Trailers are separate from initial headers, with the same ordered field API:

    $response->add_trailer('Content-Digest', $digest_field_value);
    my $digest = $response->trailer('Content-Digest');

For a message following external receipt:

    $response->mark_incomplete->freeze_initial;
    # Body receipt and trailer delivery happen in the HTTP implementation.
    $response->add_trailer('Content-Digest', $digest_field_value);
    $response->mark_complete->freeze;

C<freeze_initial()> fixes headers and metadata while body and trailers can
still be supplied. C<freeze()> fixes all data. Completeness is independent.
See L<Uniform::HTTP::Message> for section capabilities and adapter limitations.

=head1 EXTENDED CONNECT

L<Uniform::HTTP::Request> accepts an optional C<protocol> token:

    my $request = Uniform::HTTP::Request->new(
        method => 'CONNECT', protocol => 'websocket',
        scheme => 'https', authority => 'example.com', target => '/chat',
    );

Ordinary CONNECT omits C<protocol> and uses its authority-form target.
Uniform preserves this metadata; the surrounding HTTP implementation handles
negotiation and tunnel behavior. An unset C<version> permits a neutral message
without requiring the sender to modify the object.

=head1 AUTHENTICATION

L<Uniform::HTTP::Auth> prepares Basic, Bearer, and Digest authentication field
values.

    use Uniform::HTTP::Auth;

    my $auth = Uniform::HTTP::Auth->new(
        origin => 'https://example.com:443',
        credentials => {
            username => 'user',
            password => 'secret',
        },
    );

Authentication calculation is separate from sending or retrying a request.

=head1 MODULES

=over 4

=item * L<Uniform::HTTP::Message>

Shared request/response behavior.

=item * L<Uniform::HTTP::Request>

HTTP request data.

=item * L<Uniform::HTTP::Response>

HTTP response data.

=item * L<Uniform::HTTP::Auth>

HTTP Basic, Bearer, and Digest authentication.

=back

=head1 SCOPE

Uniform::HTTP represents HTTP semantics. It deliberately does not own:

=over 4

=item * sockets, TLS, or connections

=item * HTTP parsing or serialization

=item * HTTP/1 framing or HTTP/2 and HTTP/3 streams

=item * event loops

=item * streaming I/O

=item * retries, redirects, or framework lifecycle

=back

This narrow boundary is what allows the same contract to be used by unrelated
HTTP implementations.

Library authors implementing adapters should see F<docs/MESSAGE-SPEC.md> and
F<docs/ADAPTERS.md> in the distribution.

=head1 VERSION

Version 0.04.

=head1 AUTHOR

Joshua S. Day E<lt>HAX@cpan.orgE<gt>

=head1 LICENSE

This software is available under the MIT License.

=cut
