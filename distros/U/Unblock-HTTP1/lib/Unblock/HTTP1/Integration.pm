package Unblock::HTTP1::Integration;

use strict;
use warnings;

our $VERSION = '0.12';

1;

__END__

=head1 NAME

Unblock::HTTP1::Integration - How to connect the HTTP/1 engine to an event loop

=head1 START HERE

Unblock::HTTP1 speaks HTTP/1.0 and HTTP/1.1. It parses requests and responses,
enforces message framing, and produces bytes ready to send.

It does not open sockets, listen for connections, make TLS connections, or run
an event loop. Your event framework handles those jobs.

There are two kinds of code:

=over 4

=item * Application code decides which request to make or how to respond.

=item * Integration code connects a framework stream or socket to the engine.

=back

Start with the complete programs in the repository:

    examples/io-async-server.pl
    examples/io-async-client.pl
    examples/anyevent-server.pl
    examples/anyevent-client.pl
    examples/linux-event-server.pl

Each uses a framework-native Stream or Handle subclass. The example files
separate adapter code from application code with comments. The IO::Async and
AnyEvent server/client pairs can be run against one another using port 8080,
or with a different port argument. The Linux::Event server is Linux-only and
can be exercised using curl; Linux::Event is not a required dependency.

This installed page is the general integration guide. The repository also has
docs/INTEGRATION.md and docs/COOKBOOK.md.

=head1 APPLICATION CODE

On the server, the on_request callback receives one Transaction and one
canonical Uniform::HTTP::Request:

    on_request => sub {
        my ($tx, $request) = @_;
        $tx->respond(
            status => 200,
            body   => "Hello World!\n",
        );
    }

The normal form of respond() accepts named response fields. You can also pass
a Uniform::HTTP::Response object directly:

    $tx->respond($response);

A client makes one request using named fields and response callbacks:

    my $tx = $client->request(
        method    => 'GET',
        target    => '/',
        authority => 'example.test',
        on_response => sub {
            my ($tx, $response) = @_;
            print $response->status, "\n";
        },
    );

The existing canonical Uniform::HTTP::Request object form still works:

    $client->request($request, on_response => sub { ... });

You do not have to use Future objects, promises, or async/await syntax.

=head1 INTEGRATION CODE

Construct one Client or Server for one framework connection:

    my $http = Unblock::HTTP1::Server->new(
        transport  => $stream,
        on_request => $on_request,
    );

The framework stream implements these three methods:

    $stream->unblock_send($bytes);
    $stream->unblock_finish();
    $stream->unblock_abort($reason);

When the framework reads network bytes, call:

    $http->input($bytes);

On clean read-side EOF, call:

    $http->input_eof;

On a socket or TLS error, call:

    $http->transport_error($reason);

There is no want_write()/output() loop when a host transport is attached.
The engine sends outgoing data through unblock_send() automatically, including
data produced by an application callback long after input() returned.

The ordinary low-level input() API and the optional native borrowed-input ABI
remain available. Native adapters may use the latter without using a new
HTTP-level API.

=head1 HOST OUTPUT CONTRACT

=head2 unblock_send

    sub unblock_send {
        my ($self, $bytes) = @_;
        $self->write($bytes);
        return;
    }

This method receives HTTP wire bytes, not an HTTP body. The framework must
accept ALL bytes or throw an exception. A partial or rejected write is NOT a
successful return. An actual socket write may be partial internally, but the
framework must retain the remaining bytes in its own queue.

The return value describes congestion AFTER complete acceptance:

=over 4

=item * A true value: all bytes accepted; output can continue.

=item * A defined false value: all bytes accepted; the host is congested.

=item * An undefined value: all bytes accepted; no congestion signal provided.

=back

Once accepted, bytes belong to the framework and are removed from the engine
queue. They must not be requested or sent again. The engine does not write
directly to file descriptors.

If unblock_send throws, Unblock reports an error, discards its unaccepted
queue, and calls unblock_abort(). Host send callbacks must not call input(),
input_eof(), or write new HTTP output recursively.

=head2 resume_output

If unblock_send returns false, the engine stops transferring additional
buffers and streaming producers receive a false return from Transaction
write()/end(). The host must call:

    $http->resume_output;

when its own output queue becomes writable again. The engine transfers any
remaining buffers and can invoke the producer's on_drain callback.

A framework that always accepts output into its queue can return undef and
omit resume_output() entirely.

=head2 unblock_finish

The engine calls this once after a graceful HTTP close, and only after every
remaining output buffer has been accepted by unblock_send.

The framework must finish sending its already accepted bytes BEFORE closing
the underlying stream:

    sub unblock_finish {
        my ($self) = @_;
        $self->close_when_empty;
    }

The exact graceful-close operation belongs to the framework.

=head2 unblock_abort

An unusable transport, fatal send exception, or cancelled HTTP/1 transaction
requires immediate abort:

    sub unblock_abort {
        my ($self, $reason) = @_;
        $self->close_now;
    }

This may discard queued network bytes. Do not implement it as a graceful close.

=head1 OWNERSHIP AND LIFETIME

The framework owns its socket, stream, event loop, timers, TLS session, and
write queue. The HTTP engine owns HTTP parser and Transaction state.

An attached HTTP engine holds a WEAK reference to its transport. This lets a
framework Stream subclass own an engine without forming a direct reference
cycle. The Stream must stay alive while work is pending. If it disappears,
the engine reports a transport failure on its next output attempt.

Application callbacks can still create cycles if they capture their own
Stream strongly while the Stream holds the HTTP engine. Prefer callbacks
that receive the Transaction, use weak captures, or explicitly release
callback references at teardown.

Once a Transaction is complete, cancelled, or errored, it is terminal.
Calling respond(), write(), or end() afterward is an error. A Transaction
does not own the socket and cannot outlive the HTTP engine as a functioning
writer.

=head1 EOF, CLOSE AND DELAYED RESPONSES

input_eof() means the peer has finished sending bytes. It is NOT the same as
a socket failure. A fully received request may still have an outstanding
application response. That response can be sent later and then gracefully
finished; the connection cannot be reused after read EOF.

If EOF truncates an unfinished request, the server handles it as an HTTP
error. A client handles EOF according to the HTTP response framing, including
close-delimited response bodies.

transport_error() is for a broken underlying transport. It aborts immediately,
not after queued output.

close() explicitly closes HTTP protocol state and fails outstanding exchanges.
When a host is attached, any HTTP output already queued is handed off before
the host's graceful finish. Cancelling an HTTP/1 Transaction instead aborts
the underlying connection because HTTP/1 cannot independently cancel an
in-flight exchange without corrupting framing.

Calling input_eof(), transport_error(), or close() repeatedly is safe once the
corresponding terminal condition has been reached.

=head1 HTTP CALLBACKS

A server's required on_request callback receives:

    ($tx, $request)

Optional server callbacks:

    on_body        => sub { my ($tx, $request, $bytes) = @_ }
    on_request_end => sub { my ($tx, $request) = @_ }
    on_error       => sub { my ($tx, $reason) = @_ }
    on_switch      => sub { my ($tx, $response) = @_ }

on_request runs after the request head is parsed, possibly before its body is
complete. on_body runs for each decoded body fragment, zero or more times.
on_request_end runs when the full request and trailers are complete.

A client request can provide:

    on_informational => sub { my ($tx, $response) = @_ }
    on_response      => sub { my ($tx, $response) = @_ }
    on_body          => sub { my ($tx, $response, $bytes) = @_ }
    on_complete      => sub { my ($tx) = @_ }
    on_error         => sub { my ($tx, $reason) = @_ }
    on_switch        => sub { my ($tx, $response) = @_ }
    on_drain         => sub { my ($tx) = @_ }

on_response runs after a final response head arrives. on_body delivers
decoded response body fragments. on_complete runs when the response and
outgoing request are complete. Informational responses are distinct and do
not replace the final response object.

For streaming output, respond(stream_body => 1) on the server or
request(stream_body => 1) on the client enables write(), end(), and on_drain.
A false write()/end() return indicates congestion, not rejected bytes.
Callbacks may defer their work. Errors thrown by HTTP callbacks are handled
as connection/protocol failures; do not expect a callback's return value to
mean that the framework socket sent bytes.

=head1 INCOMING BODY MODES AND TERMINAL CALLBACKS

Incoming bodies stream by default. An integration may configure a Client or
Server with C<receive_body =E<gt> 'buffered'> to collect decoded incoming
body bytes on the canonical Uniform::HTTP message. Buffered reception has a
C<max_buffered_body_bytes> limit, defaulting to 64 MiB.

For a particular Transaction, register C<$tx-E<gt>on_data(sub { ... })> during
the incoming-header callback to receive decoded fragments without retaining
the entire body. Client C<request()> may also take C<on_data> directly.
Do not combine C<on_data> with C<on_body> on the same Transaction.

C<$tx-E<gt>on_finish(sub { ... })> runs exactly once when the Transaction
becomes complete, cancelled, or errored, after the corresponding normal
completion/error callbacks. Client C<request()> also accepts C<on_finish>.
For an attached server, successful completion waits until the framework
has accepted the outgoing HTTP bytes, not until the network has delivered
them. Consult L<Unblock::HTTP1::Transaction> for callback ordering and
registration rules.

=head1 UPGRADE AND CONNECT

On a valid 101 Upgrade response or a successful CONNECT exchange, the engine
sets is_switched() and stops treating incoming bytes as HTTP.

In ordinary Perl input mode, the bytes already received after the HTTP
handshake can be obtained exactly once using:

    my $tail = $http->take_remainder;

The next protocol consumer owns those bytes. In native borrowed-input mode,
the native consumer instead retains the reported unconsumed tail.

When a transport is attached, a server on_switch callback fires only AFTER
all outgoing handshake bytes have been accepted by the host. The bytes may
still be waiting in the framework's own write queue. Maintain that write
order while transitioning the framework connection to its next protocol.

Do not feed the remainder back to the HTTP engine as HTTP. HTTP1 signals the
transition but does not itself instantiate a WebSocket or other consumer.

=head1 LOW-LEVEL MODE AND NATIVE INPUT

If no transport is supplied, the engine retains the existing manual API:

    $http->input($bytes);
    while ($http->want_write) {
        $framework->write($http->output);
    }

This is useful for custom/native applications and debugging.

With transport attached, calling output() is an error. Choose one output
ownership mode per HTTP connection.

Unblock::HTTP1::NativeABI provides the optional XS borrowed-buffer input path,
with the same HTTP-level events and output behavior. It is transport neutral
and does not require new socket abstractions.

=head1 SEE ALSO

L<Unblock::HTTP1>,
L<Unblock::HTTP1::Client>,
L<Unblock::HTTP1::Server>,
L<Unblock::HTTP1::Transaction>,
L<Unblock::HTTP1::NativeABI>

=cut
