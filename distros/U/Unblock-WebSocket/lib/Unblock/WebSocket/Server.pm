package Unblock::WebSocket::Server;

use strict;
use warnings;

our $VERSION = '0.02';
use parent 'Unblock::WebSocket::_Engine';

sub new {
    my ($class, %option) = @_;
    return $class->_new(role => 'server', %option);
}

1;

__END__

=head1 NAME

Unblock::WebSocket::Server - server side of an established WebSocket connection

=head1 SYNOPSIS

    use Unblock::WebSocket::Server;

    # The opening HTTP handshake must already be complete.
    my $ws = Unblock::WebSocket::Server->new(
        on_message => sub {
            my ($ws, $message, $type) = @_;
            $ws->send_text("echo:$message");
        },
    );

    # Receive WebSocket bytes from a connection:
    $ws->input($bytes);

    # Manual mode: move outgoing bytes to the transport write queue.
    while ($ws->want_write) {
        $host->write($ws->output);
    }

=head1 DESCRIPTION

Server handles the WebSocket protocol for a server-side connection.
It expects incoming client frames to be masked and sends unmasked
frames back.

It does not create a listener, accept sockets, perform TLS, or send
the opening HTTP response.

First validate the incoming HTTP request with
L<Unblock::WebSocket::Handshake/server_accept> and send its
C<server_response()> through your HTTP implementation. Once the
HTTP connection has switched to WebSocket, create Server:

    my $ws = Unblock::WebSocket::Server->new(
        %{ $handshake->connection_options },
        on_message => sub {
            my ($ws, $message, $type) = @_;
            $ws->send_text($message);
        },
    );

The connection options include negotiated compression, if any.

=head1 CHOOSING OUTPUT MODE

The manual mode uses C<input($bytes)> to receive data and C<output()>
while C<want_write()> is true to retrieve wire bytes. The caller
writes the bytes to its ordered transport queue.

In attached mode:

    my $ws = Unblock::WebSocket::Server->new(
        transport => $host,
        on_message => sub {
            my ($ws, $message, $type) = @_;
            $ws->send_text($message);
        },
    );

The host implements C<unblock_send($bytes)>, C<unblock_finish()> and
C<unblock_abort($reason)>. The engine automatically sends outgoing
WebSocket bytes through C<unblock_send()>.

The host must accept the entire buffer or throw. If it returns a
defined false value, every byte was accepted but the host is congested.
Call C<$ws-E<gt>resume_output()> when the host is ready to accept more.

In attached mode C<output()> is not available. The transport must
remain alive while the WebSocket connection is in use; the engine
holds only a weak reference to it.

=head1 MESSAGES AND CLOSE

C<on_message> receives C<($ws, $payload, $type)> where C<$type>
is C<text> or C<binary>. Use C<send_text()> and C<send_binary()> to
reply. Received Ping frames are answered automatically.

Other callbacks are C<on_ping>, C<on_pong>, C<on_close>, C<on_error>
and C<on_drain>.

A false send return means the message was accepted but the producer
should pause until C<on_drain>.

C<close()> starts a WebSocket Close handshake. In attached mode
C<unblock_finish()> is called after the peer Close and pending
protocol output are handled. The host must drain its own write
queue before shutting down. Use C<input_eof()> on read-side EOF
or C<transport_error($reason)> for a transport failure.

See L<Unblock::WebSocket/ESTABLISHED CONNECTION API> for the method
reference and C<docs/INTEGRATION.md> for HTTP/1, HTTP/2 and HTTP/3
integration.

=cut
