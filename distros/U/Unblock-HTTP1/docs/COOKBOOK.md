# Unblock::HTTP1 Cookbook

This cookbook starts with running programs, not HTTP internals.

The examples are complete programs. The source is in examples/ and each file
separates ADAPTER CODE from APPLICATION CODE with comments.

## Run a server and client

Choose either event framework:

    perl examples/io-async-server.pl
    perl examples/io-async-client.pl

or:

    perl examples/anyevent-server.pl
    perl examples/anyevent-client.pl

The Linux-only server example uses Linux::Event:

    perl examples/linux-event-server.pl

Use curl to request a response from the Linux::Event server.

Servers listen on port 8080 unless you supply another port argument. Clients
connect to 127.0.0.1 on that port.

From another terminal, you can also run:

    curl -v http://127.0.0.1:8080/

## Application code

The application does not need to create Uniform::HTTP objects:

    on_request => sub {
        my ($tx, $request) = @_;
        $tx->respond(
            status => 200,
            body   => "hello\n",
        );
    }

A client can make a request just as directly:

    $client->request(
        method    => 'GET',
        target    => '/',
        authority => 'example.test',
        on_response => sub {
            my ($tx, $response) = @_;
            print $response->status, "\n";
        },
    );

For a streaming response:

    $tx->respond(
        status      => 200,
        stream_body => 1,
        on_drain    => sub { produce_more() },
    );
    $tx->write($first_chunk);
    $tx->end($last_chunk);

Write and end can return false when output queues are congested. Their
arguments are still accepted. Pause until on_drain.

## What the adapter does

One framework connection owns one HTTP Client or Server object.

    framework read         -> $http->input($bytes)
    framework clean EOF    -> $http->input_eof
    framework failure      -> $http->transport_error($error)
    framework writable     -> $http->resume_output (only if blocked)

And the framework implements:

    unblock_send($bytes)
    unblock_finish()
    unblock_abort($error)

The engine asks the framework to send generated HTTP bytes automatically. An
adapter no longer needs to poll want_write() and call output().

unblock_send accepts all bytes into the framework's write queue, or throws.
It can return a false value to indicate congestion after complete acceptance.
unblock_finish means close AFTER all queued bytes are sent. unblock_abort
means close immediately and discard anything still queued.

The host is weakly held by HTTP. A framework-native subclass can own HTTP
without HTTP creating a direct ownership cycle.

## IO::Async

Server: examples/io-async-server.pl
Client: examples/io-async-client.pl

Each defines a subclass of IO::Async::Stream.

The server's on_accept callback constructs its Stream subclass from the
accepted socket, then adds the stream to the event loop. The application
callback is defined separately so it is not nested inside the constructor.

The subclass constructs its own HTTP engine in new(). There is no separate
attach_http() call or transport wrapper. The client follows the same pattern
after IO::Async::Loop->connect returns a connected socket.

Both implement unblock_send with the framework's write() method and implement
unblock_finish with close_when_empty(). The examples do not expose framework
backpressure; unblock_send returns undef once bytes are queued.

## AnyEvent

Server: examples/anyevent-server.pl
Client: examples/anyevent-client.pl

Each defines a subclass of AnyEvent::Handle, using on_read/on_eof/on_error
for incoming events and push_write for outgoing bytes. unblock_finish waits
for AnyEvent's on_drain before destroying the Handle.

The server maintains active Handle references until each connection closes.
The HTTP engine holds a weak pointer back to its Handle.

## Linux::Event

Server: examples/linux-event-server.pl

The class Example::HTTPStream subclasses Linux::Event::IO::Sock::Stream.
It creates its HTTP engine in new(), then maps on_data, on_eof,
on_error and on_drain to the corresponding engine operations.

The three unblock_* methods map to write(), end() and close().
Linux::Event write() accepts queued bytes even when it returns false
for congestion. If a hard output limit closes the stream, the adapter
throws rather than claiming the bytes were accepted.

Example::HelloHTTPStream implements on_http_request() with ordinary
application logic. The Linux::Event Listener creates instances of
that subclass using its stream => { class => ... } recipe.
The example shows plain HTTP only, not Upgrade/CONNECT handoff.

Linux::Event is optional and Linux-only. Unblock::HTTP1 itself remains
event-loop and operating-system neutral.

## Delayed responses

A server callback can keep the Transaction:

    my $pending;
    on_request => sub { $pending = $_[0] };

Later, a timer or database callback may call:

    $pending->respond(status => 200, body => 'ready');

The engine hands off this output immediately, even though the socket's most
recent read callback has long since finished. The framework does not need to
run another HTTP output pump.

If the peer cleanly shuts down its sending side after a complete request, the
Transaction can still reply. No new request can use the connection after that
read-side EOF.

## Upgrade and CONNECT

A valid 101 response or successful CONNECT stops HTTP parsing. The on_switch
callback announces the transition.

In ordinary Perl input mode:

    my $tail = $http->take_remainder;

The tail belongs to the next protocol. When an attached host is used, the
server on_switch callback is held until handshake bytes have been accepted
into the host output queue. A native borrowed-input consumer instead keeps
the unconsumed tail reported by the ABI.

The examples above intentionally show ordinary HTTP traffic; they do not
implement a WebSocket or a tunnel after switching.

## Native integrations

Advanced XS hosts may use Unblock::HTTP1::NativeABI for borrowed input. It
does not require a different application API and does not own the native
buffer. The ABI is still input-focused.

See perldoc Unblock::HTTP1::Integration for detailed lifecycle, callback,
reentrancy, and byte ownership rules.
