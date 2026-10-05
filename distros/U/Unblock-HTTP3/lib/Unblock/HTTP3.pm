package Unblock::HTTP3;

use strict;
use warnings;

use XSLoader ();

our $VERSION = '0.03';

XSLoader::load(__PACKAGE__, $VERSION);

1;

__END__

=head1 NAME

Unblock::HTTP3 - non-blocking HTTP/3 protocol engine for Perl

=head1 SYNOPSIS

    use Unblock::HTTP3::Connection;
    use Uniform::HTTP::Request;

    my $h3 = Unblock::HTTP3::Connection->client(
        quic => $quic,
    );

    $h3->start;

    my $tx = $h3->request(
        Uniform::HTTP::Request->new(
            method    => 'GET',
            target    => '/',
            scheme    => 'https',
            authority => 'example.com',
        ),
    );

=head1 DESCRIPTION

Unblock::HTTP3 is an HTTP/3 protocol engine.

It sits above L<Net::QUIC> and uses L<Uniform::HTTP> request and response
objects. It does not own UDP sockets, timers, TLS configuration, or an event
loop.

libnghttp3 is supplied through L<Alien::nghttp3> and is used for HTTP/3 framing
and QPACK.

The main public objects are L<Unblock::HTTP3::Connection> and
L<Unblock::HTTP3::Transaction>. Streaming bodies, Capsules, HTTP Datagrams,
Extended CONNECT, extension SETTINGS, extension streams, priorities, graceful
shutdown, and replay-aware 0-RTT are built around those objects.

=head1 STANDARDS

Unblock::HTTP3 implements the HTTP/3 protocol defined by RFC 9114 with QPACK
from RFC 9204. It also supports RFC 9218 priorities, RFC 9220 Extended CONNECT,
RFC 9297 HTTP Datagrams and Capsules, and RFC 9412 ORIGIN.

QUIC transport behavior remains the responsibility of L<Net::QUIC>.

Detailed conformance notes and native-library limitations are recorded in
C<docs/RFC-COMPLIANCE.md> in the distribution.

=head1 MODULES

=over 4

=item L<Unblock::HTTP3::Connection>

One HTTP/3 connection over one Net::QUIC connection.

=item L<Unblock::HTTP3::Transaction>

One HTTP/3 request stream and its response.

=item L<Unblock::HTTP3::NativeABI>

Optional versioned native consumer ABI for XS integrations.

=item L<Uniform::HTTP::Request> and L<Uniform::HTTP::Response>

Canonical HTTP message objects used directly by Unblock::HTTP3.

=item L<Unblock::HTTP3::Body::Stream>

Writable outgoing body stream.

=item L<Unblock::HTTP3::Body::Reader>

Readable incoming body stream.

=back

=head1 SEE ALSO

L<Net::QUIC>, L<Uniform::HTTP>, L<Alien::nghttp3>, L<Unblock::HTTP3::NativeABI>

=head1 AUTHOR

Joshua S. Day

=head1 LICENSE

This software is available under the MIT License.

=cut
