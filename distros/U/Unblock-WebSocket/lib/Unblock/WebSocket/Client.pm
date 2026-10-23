package Unblock::WebSocket::Client;

use strict;
use warnings;

our $VERSION = '0.02';
use parent 'Unblock::WebSocket::_Engine';

sub new {
    my ($class, %option) = @_;
    return $class->_new(role => 'client', %option);
}

1;

__END__

=head1 NAME

Unblock::WebSocket::Client - client side of an established WebSocket connection

=head1 SYNOPSIS

    use Unblock::WebSocket::Client;

    # The opening HTTP handshake must already be complete.
    my $ws = Unblock::WebSocket::Client->new(
        on_message => sub {
            my ($ws, $message, $type) = @_;
            print "Received $type: $message\n";
        },
    );

    $ws->send_text('hello');

    # Manual mode: move these bytes to the transport write queue.
    while ($ws->want_write) {
        $host->write($ws->output);
    }

    # When the transport receives new WebSocket bytes:
    $ws->input($bytes);

=head1 DESCRIPTION

Client encodes and decodes WebSocket frames for the client end of a
connection. It masks outgoing messages as required by RFC 6455.

It does not open a socket, send an HTTP request, or run an event loop.

First create an HTTP request with
L<Unblock::WebSocket::Handshake/client_request>, send it using your HTTP
implementation, and validate the response. Then create Client:

    my $ws = Unblock::WebSocket::Client->new(
        %{ $handshake->connection_options },
        on_message => sub { ... },
    );

The connection options carry negotiated compression, if any.

=head1 CHOOSING OUTPUT MODE

Without a C<transport> option, use C<input($bytes)> for incoming bytes
and C<output()> while C<want_write()> is true for outgoing bytes.
The caller must preserve outgoing byte order.

For attached output, supply a host object:

    my $ws = Unblock::WebSocket::Client->new(
        transport => $host,
        on_message => sub { ... },
    );

The host must implement C<unblock_send($bytes)>, C<unblock_finish()>
and C<unblock_abort($reason)>. The engine sends outgoing buffers to
that host automatically. Its C<unblock_send()> must accept every byte
or throw. A defined false return means it accepted every byte but is
congested; call C<$ws-E<gt>resume_output()> once it can accept more.

The host owns the socket, its write queue, TLS, EOF, and timers.
Use C<input_eof()> when its read side ends or
C<transport_error($reason)> when it fails. Do not call C<output()>
with a host attached.

=head1 MESSAGES AND CALLBACKS

C<send_text($text)> sends a UTF-8 text message.
C<send_binary($bytes)> sends a binary message.
C<ping($payload)> sends a Ping; received Ping frames are answered
automatically.

C<on_message> receives C<($ws, $payload, $type)> where C<$type>
is C<text> or C<binary>. Other callbacks are C<on_ping>, C<on_pong>,
C<on_close>, C<on_error>, and C<on_drain>.

C<close(code =E<gt> 1000, reason =E<gt> 'done')> starts the WebSocket
Close handshake. It is not an immediate socket shutdown.

A false return from a send method still means the message was
accepted. Pause producing messages until C<on_drain> fires.

See L<Unblock::WebSocket/ESTABLISHED CONNECTION API> for all options
and methods, and C<docs/INTEGRATION.md> for detailed host rules.

=cut
