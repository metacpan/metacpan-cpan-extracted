package Unblock::HTTP3;

use strict;
use warnings;

use XSLoader ();

our $VERSION = '0.13';

XSLoader::load(__PACKAGE__, $VERSION);

1;

__END__

=head1 NAME

Unblock::HTTP3 - non-blocking HTTP/3 protocol engine for Perl

=head1 SYNOPSIS

    use Unblock::HTTP3::Client;

    my $client = Unblock::HTTP3::Client->new(
        quic => $quic,
    );

    $client->start;

    my $transaction = $client->request(
        method    => 'GET',
        target    => '/',
        scheme    => 'https',
        authority => 'example.com',
        on_response => sub {
            my ($transaction, $response) = @_;
            print $response->status, "\n";
        },
    );

=head1 DESCRIPTION

Unblock::HTTP3 is an HTTP/3 protocol engine.

It sits above L<Net::QUIC> and uses the Uniform HTTP message contract. Exact
canonical L<Uniform::HTTP::Request> and L<Uniform::HTTP::Response> objects use
the native fast path. Adapters and subclasses use the portable Perl contract.

It does not own UDP sockets, timers, TLS configuration, or an event loop.

libnghttp3 is supplied through L<Alien::nghttp3> and is used for HTTP/3 framing
and QPACK.

The public API is built around L<Unblock::HTTP3::Client>,
L<Unblock::HTTP3::Server>, and L<Unblock::HTTP3::Transaction>. The common
application vocabulary intentionally matches the other Unblock HTTP engines:
C<new()>, C<request()>, C<respond()>, C<write()>, C<end()>, and
C<send_informational()>.

HTTP/3-specific features such as Datagrams, Capsules, Extended CONNECT, 0-RTT,
QPACK state, priorities, RESET_STREAM, and STOP_SENDING remain protocol-specific.

=head1 MODULES

=over 4

=item L<Unblock::HTTP3::Client>

One client HTTP/3 connection over an existing Net::QUIC connection.

=item L<Unblock::HTTP3::Server>

One server HTTP/3 connection over an existing Net::QUIC connection.

=item L<Unblock::HTTP3::Integration>

Event-loop and QUIC Driver integration guide, with complete examples.

=item L<Unblock::HTTP3::Transaction>

One HTTP request/response transaction carried by an HTTP/3 request stream.

=item L<Unblock::HTTP3::Body::Stream>

Advanced writable streaming-body API.

=item L<Unblock::HTTP3::Body::Reader>

Advanced readable streaming-body API.

=item L<Unblock::HTTP3::NativeABI>

Optional versioned native consumer ABI for XS integrations.

=back

=head1 STANDARDS

Unblock::HTTP3 implements RFC 9114 with QPACK from RFC 9204. It also supports
RFC 9218 priorities, RFC 9220 Extended CONNECT, RFC 9297 HTTP Datagrams and
Capsules, and RFC 9412 ORIGIN.

QUIC transport behavior remains the responsibility of L<Net::QUIC>.

=head1 SEE ALSO

L<Net::QUIC>, L<Uniform::HTTP>, L<Alien::nghttp3>

=head1 AUTHOR

Joshua S. Day

=head1 LICENSE

This software is available under the MIT License.

=cut
