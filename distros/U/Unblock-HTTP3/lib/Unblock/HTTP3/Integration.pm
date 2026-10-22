package Unblock::HTTP3::Integration;

use strict;
use warnings;

our $VERSION = '0.13';

1;

__END__

=head1 NAME

Unblock::HTTP3::Integration - Connect HTTP/3 to an event loop through Net::QUIC

=head1 START HERE

Unblock::HTTP3 handles HTTP/3. Net::QUIC handles QUIC and TLS 1.3. Your event
framework handles UDP datagrams and one replaceable timer.

There are two separate jobs:

=over 4

=item * Application code uses Client, Server, and Transaction.

=item * Integration code connects the event framework to Net::QUIC::Driver.

=back

The HTTP/3 application API looks like HTTP1 and HTTP2, but the transport
boundary is different. UDP is packet-oriented and cannot use the HTTP1/HTTP2
C<input($bytes)> or C<unblock_send($bytes)> stream contract.

Complete examples are included in the repository:

    examples/linux-event-server.pl
    examples/linux-event-client.pl

These require Linux::Event as an optional dependency. They have no
async/await requirement.

=head1 APPLICATION CODE

In a server request callback:

    on_request => sub {
        my ($tx, $request) = @_;
        $tx->respond(status => 200, body => "Hello World!\n");
    }

In a client:

    $client->request(
        method => 'GET',
        target => '/',
        scheme => 'https',
        authority => 'localhost',
        on_response => sub {
            my ($tx, $response) = @_;
            print $response->status, "\n";
        },
        on_body => sub {
            my ($tx, $response, $bytes) = @_;
            print $bytes;
        },
    );

These examples use named message fields; existing Uniform::HTTP objects are
also accepted. Callbacks receive the canonical Uniform message objects.

=head1 INTEGRATION CODE

Use Net::QUIC::Driver. Do not write a second QUIC packet pump inside
Unblock::HTTP3.

The event framework supplies two callbacks to Driver:

    send => sub {
        my ($datagram) = @_;
        # Accept one COMPLETE UDP datagram, with its peer address.
        # True: ready to accept another. False: accepted but congested.
    },

    set_timeout => sub {
        my ($seconds) = @_;
        # Replace the previous one-shot timer.
        # undef means cancel the timer.
    },

The framework then forwards these events to the Driver:

    $driver->start;
    $driver->receive($bytes, $packed_local, $packed_peer);
    $driver->timeout;
    $driver->writable;

C<writable()> must be called after UDP output congestion clears if the
C<send> callback previously returned false.

One QUIC Driver can serve multiple connections on a server UDP socket. It
handles packet production, retransmission timers, and QUIC send backpressure.
No application-visible C<while> packet-pump loop is required.

=head1 CONNECTING HTTP/3 TO QUIC

On the client, the Driver exposes an existing QUIC connection:

    my $quic = $driver->connection;

After the handshake, when C<$quic-E<gt>ready> is true:

    my $client = Unblock::HTTP3::Client->new(quic => $quic);
    $client->start;

    $client->request(
        method => 'GET', target => '/', scheme => 'https',
        authority => 'localhost', on_response => sub { ... },
    );

For a server, pull each new QUIC connection from Driver:

    while (my $quic = $driver->next_connection) {
        my $server = Unblock::HTTP3::Server->new(
            quic => $quic,
            on_request => sub {
                my ($tx, $request) = @_;
                $tx->respond(status => 200, body => "hello\n");
            },
        );

        # Retain $server alongside $quic until the connection closes.
        # Call $server->start once $quic->ready is true.
    }

HTTP/3 C<start()> registers QUIC stream-activity callbacks and services
pending streams. The application must not replace those QUIC callbacks after
starting HTTP/3.

A QUIC connection may be visible before its TLS handshake is complete. For
normal 1-RTT operation, call HTTP/3 C<start()> only once the connection is
ready. HTTP/3 0-RTT is an advanced exception requiring remembered settings.

On the server, new QUIC connections can arrive during C<receive()>. Check for
new connections after UDP input and start those that have become ready.
Also check readiness following timer events. The complete examples show this
without making the HTTP/3 engine own UDP or an event loop.

=head1 OWNERSHIP

=over 4

=item * The event loop owns the UDP socket and timer.

=item * Net::QUIC::Driver owns the QUIC endpoint.

=item * One Unblock::HTTP3::Client or Server owns HTTP/3 state for one QUIC connection.

=item * The application holds its HTTP/3 objects until their connections close.

=back

Do not give multiple HTTP/3 engines the same QUIC connection. HTTP/3 installs
the stream callbacks it needs in that connection.

=head1 HTTP/3-SPECIFIC FEATURES

HTTP/3 Datagrams, Capsules, Extended CONNECT, 0-RTT, QPACK, ORIGIN and
priorities remain available through the HTTP/3 classes. Net::QUIC::Driver
only manages the QUIC transport.

=head1 SEE ALSO

L<Unblock::HTTP3::Client>, L<Unblock::HTTP3::Server>,
L<Unblock::HTTP3::Transaction>, L<Net::QUIC::Driver>,
L<Net::QUIC::Connection>

=head1 LICENSE

MIT License.

=cut
