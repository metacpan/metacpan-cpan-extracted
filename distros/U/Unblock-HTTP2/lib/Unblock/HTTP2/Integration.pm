package Unblock::HTTP2::Integration;

use strict;
use warnings;

our $VERSION = '0.11';

1;

__END__

=head1 NAME

Unblock::HTTP2::Integration - Connect an HTTP/2 engine to an event framework

=head1 START HERE

Unblock::HTTP2 is an HTTP/2 protocol engine, not a socket or event loop.
The framework owns TCP, TLS, ALPN, timers, and its outgoing write queue.

There are two different jobs:

=over 4

=item * Application code chooses requests and responses.

=item * Integration code moves network bytes to and from the engine.

=back

One framework connection owns one Unblock::HTTP2::Client or
Unblock::HTTP2::Server. Many Transactions can share that single connection.

The repository includes a complete Linux::Event example:

    examples/linux-event-server.pl

Read docs/COOKBOOK.md for an introduction.

=head1 APPLICATION CODE

A server request callback receives the Transaction and a canonical
Uniform::HTTP::Request:

    on_request => sub {
        my ($tx, $request) = @_;
        $tx->respond(
            status => 200,
            body   => "Hello World!\n",
        );
    }

You can still provide a Uniform::HTTP::Response object:

    $tx->respond($response);

The client accepts request fields and callback options together:

    $client->request(
        method    => 'GET',
        target    => '/',
        scheme    => 'https',
        authority => 'example.test',
        on_response => sub {
            my ($tx, $response) = @_;
            print $response->status, "\n";
        },
    );

Or pass an existing Uniform::HTTP::Request as the first argument.
No Futures or async/await syntax are required.

=head1 ATTACHED TRANSPORT

Construct one Client or Server for one framework connection:

    $self->{http2} = Unblock::HTTP2::Server->new(
        transport  => $self,
        on_request => $on_request,
    );

The framework object must implement these methods:

    unblock_send($bytes)
    unblock_finish()
    unblock_abort($reason)

Feed decrypted network bytes to the engine:

    $http->input($bytes);

Call the following on transport events:

    $http->input_eof;                  # clean read-side EOF
    $http->transport_error($reason);   # fatal socket or TLS failure

The engine emits outgoing HTTP/2 wire bytes automatically through
unblock_send(). This also happens if an application produces a response
later from a timer or other callback. No manual output pump is required.

The engine holds a WEAK reference to the framework object. The framework
object must keep the engine alive while it owns a live connection.

=head1 OUTPUT OWNERSHIP

=head2 unblock_send

    sub unblock_send {
        my ($self, $bytes) = @_;
        $self->write($bytes);
        return;  # framework owns the whole queued buffer
    }

Every call passes HTTP/2 wire bytes, not just a response body. The framework
must accept the ENTIRE buffer into its outgoing queue, or throw an error.
It may write the buffer to the socket in smaller pieces later.

A true return means the complete buffer was accepted and output may
continue. An undefined return means the complete buffer was accepted but
the framework provides no congestion signal. A defined false return means
the complete buffer was accepted and the framework is NOW congested.

False does NOT mean a rejected or partially accepted buffer. A rejected
buffer must throw; the engine aborts instead of retransmitting uncertain
bytes. The engine never calls write(2) itself.

=head2 resume_output

If unblock_send() reports congestion, the engine stops handing over more
wire buffers. The framework must later call:

    $http->resume_output;

Only call this when the framework is ready to accept additional output.
A framework that always queues all output can return undef and never call
resume_output(). Transaction write() can also return false when its own
HTTP/2 streaming queue is congested. Use the Transaction's on_drain
callback to resume streaming production.

=head2 unblock_finish

This is a graceful transport finish, requested when an explicit close has
completed its output handoff. It must send ALL bytes already accepted into
the framework queue before closing the underlying socket.

    sub unblock_finish {
        my ($self) = @_;
        $self->close_when_empty;
    }

Calling HTTP2 close() is not the normal HTTP/2 connection-drain protocol.
Use drain() or goaway() to tell the peer that new streams are no longer
accepted, and allow existing streams to finish.

=head2 unblock_abort

A broken transport, fatal host send, or fatal engine failure calls:

    unblock_abort($reason)

This immediately closes the underlying transport, even if output remains
queued. Do not implement unblock_abort() as a graceful close.

=head1 EOF AND ERRORS

HTTP/2 does not use TCP EOF to delimit individual HTTP messages.
input_eof() therefore closes the HTTP/2 session and fails any unfinished
Transactions. It is idempotent once closed. A TCP half-close is not a
successful HTTP/2 response terminator.

A fatal transport_error() aborts the host immediately, fails outstanding
Transactions and is safe to call more than once.

Do not call input() or input_eof() recursively from an HTTP/2 session
callback or from unblock_send(). Let the current callback return first.

=head1 MULTIPLEXING

One HTTP/2 connection can carry several requests and responses at once.
Every request has its own Transaction, which retains its stream ID, state,
callbacks, body accounting, and flow control.

Transaction cancel() sends a stream reset; it does not automatically abort
the underlying connection. GOAWAY and SETTINGS remain connection-wide
operations.

To stream a response:

    $tx->respond(status => 200, stream_body => 1);
    my $ready = $tx->write($chunk);
    $tx->end($last_chunk);

A false write() result means the chunk WAS accepted and the producer should
pause. on_drain allows producing more later.

For slow incoming body consumers, auto_consume(0) and consume($n) still
control HTTP/2 receive-window accounting per stream.

=head1 TLS AND ALPN

Unblock::HTTP2 does not provide TLS. An adapter normally feeds decrypted
bytes after ALPN chooses "h2". Cleartext prior-knowledge HTTP/2 is possible
when both peers agree on HTTP/2 before exchanging bytes.

HTTP/1.1 Upgrade negotiation (h2c) belongs to a higher-level protocol
selector; simply giving HTTP/1.1 bytes to this engine will not negotiate an
upgrade.

=head1 MANUAL AND NATIVE MODE

Without transport => $host, the original low-level API remains available:

    $http->input($bytes);
    while ($http->want_write) {
        my $bytes = $http->output;
        last unless length $bytes;
        $framework->write($bytes);
    }

Do not mix attached and manual output ownership. output() is an error when
a host is attached.

XS transports may instead use Unblock::HTTP2::NativeABI version 1 for
borrowed input and native output. That remains an ALTERNATIVE output owner;
it does not require, or change, the Perl attached-transport interface.
Do not drain the same connection through the Perl host and the native
output sink simultaneously.

=head1 SEE ALSO

L<Unblock::HTTP2>,
L<Unblock::HTTP2::Client>,
L<Unblock::HTTP2::Server>,
L<Unblock::HTTP2::Transaction>,
L<Unblock::HTTP2::NativeABI>

=cut
