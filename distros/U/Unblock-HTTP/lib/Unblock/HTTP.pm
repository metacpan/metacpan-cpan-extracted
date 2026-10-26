package Unblock::HTTP;

use strict;
use warnings;

our $VERSION = '0.03';

1;

__END__

=head1 NAME

Unblock::HTTP - One application interface for HTTP/1, HTTP/2, and HTTP/3

=head1 SYNOPSIS

    use Unblock::HTTP::Server;

    my $server = Unblock::HTTP::Server->new(
        http1 => {},
        http2 => {},
        on_request => sub {
            my ($tx, $request) = @_;
            $tx->respond(status => 200, body => "hello\n");
        },
    );

    my $engine = $server->attach_stream(
        transport => $stream,
        alpn => $negotiated_alpn,
    );
    $engine->input($bytes);

=head1 DESCRIPTION

This is the event-loop-neutral application layer over Unblock::HTTP1,
Unblock::HTTP2, and Unblock::HTTP3. It uses their common Client, Server,
and Transaction vocabulary while leaving protocol parsing to the engines.

The attachment API selects a protocol from the supplied ALPN result or an
explicit C<protocol> option. An unnegotiated TCP connection selects
HTTP/1.1 only when enabled. HTTP/3 uses an existing Net::QUIC connection.

It does not create sockets, negotiate TLS, install framework adapters, or
require any particular event loop. The optional L<Unblock::HTTP::QUIC> class manages HTTP/3 sessions
over L<Net::QUIC::Driver>. See L<Unblock::HTTP::Integration>.

=head1 IMPLEMENTATION STATUS

This release implements reusable Server attachment and a unified Client
with framework-driven connection factories, bounded per-origin pooling,
buffered and streamed HTTP requests, transaction-lifecycle callbacks,
deadlines, and graceful shutdown. HTTP/1.1 WebSocket Upgrade and
HTTP/2 and HTTP/3 Extended CONNECT are supported for both Client and Server,
with Unblock::WebSocket loaded only when WebSocket functionality is used.
Same-host authenticated Alt-Svc and unsent fallback are implemented.
Cross-host Alt-Svc and replay after dispatch are intentionally not provided.
The framework retains socket, TLS, UDP, and timer ownership.

=head1 CLASSES

=over 4

=item L<Unblock::HTTP::Client>

One reusable client definition for many destinations, with a bounded
request queue and per-origin H1/H2/H3 connection pools.

=item L<Unblock::HTTP::Server>

One reusable server definition shared by incoming connections.

=item L<Unblock::HTTP::QUIC>

HTTP/3 session management over Net::QUIC.

=item L<Unblock::HTTP::Integration>

How to connect the unified interface to a framework.

=back

=head1 LICENSE

MIT License.

=cut
