package Unblock::WebSocket;

use strict;
use warnings;

our $VERSION = '0.02';
our $NATIVE_AVAILABLE = eval {
    require XSLoader;
    XSLoader::load(__PACKAGE__, $VERSION);
    1;
} ? 1 : 0;

sub native_available { $NATIVE_AVAILABLE }

1;

__END__

=head1 NAME

Unblock::WebSocket - event-loop and platform neutral WebSocket protocol engine

=head1 SYNOPSIS

Use the Handshake helper to establish WebSocket over HTTP, then use
Client or Server for messages. The example below assumes the HTTP
handshake has already succeeded:

    use Unblock::WebSocket::Server;

    my $ws = Unblock::WebSocket::Server->new(
        on_message => sub {
            my ($ws, $message, $type) = @_;
            $ws->send_text("echo:$message");
        },
    );

    # Received WebSocket bytes, not HTTP bytes:
    $ws->input($bytes);

    # Manual output mode:
    while ($ws->want_write) {
        $host->write($ws->output);
    }

Or attach a host that implements the three transport methods:

    my $ws = Unblock::WebSocket::Server->new(
        transport => $host,
        on_message => sub {
            my ($ws, $message, $type) = @_;
            $ws->send_text($message);
        },
    );

In attached mode output is passed to the host automatically.
See the runnable C<examples/handshake-memory.pl> and
C<examples/memory-attached.pl> programs in the distribution.

=head1 DESCRIPTION

Unblock::WebSocket provides WebSocket protocol handling without owning sockets,
TLS, DNS, timers, or an event loop.

Use L<Unblock::WebSocket::Handshake> for the opening HTTP handshake.

Use L<Unblock::WebSocket::Client> or L<Unblock::WebSocket::Server> after the
WebSocket stream has been established.

The opening HTTP handshake is separate from established WebSocket traffic.
The caller carries Uniform::HTTP request and response objects using its own
HTTP implementation, then passes only WebSocket bytes to Client or Server.

The distribution supports:

=over

=item * RFC 6455 framing, masking, fragmentation, Ping/Pong, Close, and UTF-8

=item * HTTP/1.1 Upgrade handshakes

=item * HTTP/2 and HTTP/3 Extended CONNECT handshakes

=item * RFC 7692 permessage-deflate

=item * a portable Perl protocol backend

=item * a private native backend for faster framing and masking

=back

The public protocol API remains bytes in and bytes out. Applications do not
need to work with WebSocket frame objects. Output can be drained manually or
handed to an optional attached transport automatically.

=head1 INSTALLATION

Install with C<cpanm Unblock::WebSocket>. The distribution requires Perl
5.16 or newer and builds an XS extension, so a C compiler is needed for
installation from source.

=head1 NATIVE BACKEND

C<native_available()> reports whether the XS backend loaded.

When available, normal established connections use the native backend unless a
portable-only option requires otherwise. This is an implementation detail; the
public Client and Server APIs are the same.

=head1 ESTABLISHED CONNECTION API

L<Unblock::WebSocket::Client> and L<Unblock::WebSocket::Server> share the same
established-connection API.

Common constructor options include:

=over

=item C<max_message_size>

Maximum decompressed application message size. The default is 16 MiB.

=item C<high_water>

Output high-water mark. The default is 65536 bytes.

=item C<low_water>

Output low-water mark. The default is 32768 bytes.

=item C<permessage_deflate>

Negotiated RFC 7692 parameters. Normally this comes from
L<Unblock::WebSocket::Handshake/connection_options>.

=item C<transport>

Optional host transport object implementing C<unblock_send($bytes)>,
C<unblock_finish()> and C<unblock_abort($reason)>. The host owns the socket,
TLS, event loop and its ordered output queue. An attached engine holds a weak
reference to the host. Without this option, the engine uses manual output.

=item C<backend>

C<native> or C<perl>. Normal applications should let the module choose
automatically. This option is mainly useful for differential testing and
debugging.

=back

Callbacks are supplied to the constructor:

=over

=item C<on_message>

    on_message => sub {
        my ($ws, $payload, $type) = @_;
    }

C<$type> is C<text> or C<binary>.

=item C<on_ping>

Called for received Ping payloads. The protocol engine also sends the required
Pong automatically.

=item C<on_pong>

Called for received Pong payloads.

=item C<on_close>

    on_close => sub {
        my ($ws, $code, $reason) = @_;
    }

Called when a Close frame is received. A transport EOF without a Close frame
reports an undefined code and C<transport EOF> as the reason.

=item C<on_error>

Called for protocol or callback errors.

=item C<on_drain>

Called when a producer that saw a false send return can resume. In attached
mode, this also waits for host congestion to clear via C<resume_output()>.
This is not a socket writable callback.

=back

Common methods include:

=over

=item C<input($bytes)>

Feed bytes received from the ordered transport.

=item C<input_eof()>

Report transport EOF.

=item C<output([$maximum])>

Remove and return generated transport bytes in manual mode. An optional
positive maximum limits the returned chunk size. Calling this with an attached
transport is an error.

=item C<resume_output()>

With an attached transport, clear a congestion indication after the host can
accept more bytes. The host must call this after its C<unblock_send()> returned
false. Calling it in manual mode is an error.

=item C<transport_error($reason)>

Report a broken transport or TLS connection. Aborts immediately, discards
unaccepted protocol output and, in attached mode, calls C<unblock_abort()>.
This is distinct from a peer WebSocket Close frame.

=item C<want_write()>

True while generated output is waiting to be drained.

=item C<want_read()>

True while the protocol engine can still accept transport input.

=item C<output_size()>

Number of generated bytes currently buffered.

=item C<send_text($text)>

Queue one text message.

=item C<send_binary($bytes)>

Queue one binary message.

=item C<ping([$payload])>

Queue a Ping control frame. Payloads are limited to 125 bytes.

=item C<close(%options)>

Begin a normal WebSocket Close handshake. C<code> defaults to 1000 and
C<reason> is optional.

=item C<abort()>

Stop the protocol engine immediately and discard buffered output.

=item C<is_open()>, C<is_closing()>, C<is_closed()>

Inspect connection state.

=item C<close_sent()>, C<close_received()>, C<close_complete()>

Inspect the Close handshake.

=item C<want_end()>

True when the transport may be ended after pending output is drained.

=item C<backend()>

Returns C<native> or C<perl>.

=item C<permessage_deflate()>

Returns the negotiated compression parameters, or undef.

=back

C<send_text()>, C<send_binary()>, and C<ping()> accept their bytes even when
the output high-water mark is reached. A false return means the producer should
pause until C<on_drain> runs. In attached mode, false may also mean that the
host accepted an entire buffer but reported congestion. Host send methods
must accept all bytes or throw, and must drain their own write queues before
a graceful C<unblock_finish()> shuts the connection.

C<close()> queues a WebSocket Close frame; it does not immediately terminate
the transport. The peer Close response, outstanding output and any host
congestion are handled before graceful finish. Unexpected EOF or a transport
error aborts an attached host. See C<docs/INTEGRATION.md> in the repository.

=head1 LICENSE

MIT License.

=cut
