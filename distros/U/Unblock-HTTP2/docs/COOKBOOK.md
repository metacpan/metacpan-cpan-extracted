# Unblock::HTTP2 cookbook

This guide separates using HTTP/2 from integrating HTTP/2 with an event
framework. Most applications only need the first part.

## Run the example

Complete adapter and application programs are at:

    examples/linux-event-server.pl
    examples/io-async-server.pl
    examples/io-async-client.pl
    examples/anyevent-server.pl
    examples/anyevent-client.pl

Run the IO::Async server and client in separate terminals, or use the
AnyEvent pair. Both use cleartext HTTP/2 with prior knowledge.

The Linux::Event server is at:

    examples/linux-event-server.pl

On Linux with Linux::Event installed and Perl 5.36 or newer:

    perl examples/linux-event-server.pl 8080

The Linux::Event example uses Perl signatures. The Unblock::HTTP2
distribution itself supports Perl 5.16 and newer. The IO::Async and
AnyEvent examples do not require signature syntax.

In another terminal, use curl built with HTTP/2 support:

    curl --http2-prior-knowledge http://127.0.0.1:8080/

This example serves cleartext HTTP/2 with prior knowledge. It does NOT
negotiate h2c Upgrade. For TLS, the framework must perform TLS and ALPN
and pass decrypted h2 bytes to Unblock.

## Application: a server response

    on_request => sub {
        my ($tx, $request) = @_;
        $tx->respond(
            status => 200,
            body   => "Hello World!\n",
        );
    }

The callback receives a Transaction and a canonical Uniform Request.
respond() accepts named fields or a Uniform Response object.

An HTTP/2 server can keep a Transaction for later use:

    my $pending;
    on_request => sub { $pending = $_[0] };

From a timer or database callback:

    $pending->respond(status => 200, body => 'ready');

The engine hands those outgoing bytes to the framework immediately.

## Application: a client request

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

A single Client supports multiple active requests at the same time.
Response and body callbacks are specific to each Transaction.

## Streaming

    $tx->respond(status => 200, stream_body => 1);
    my $ready = $tx->write($first_chunk);
    $tx->end($last_chunk);

A false write() result means the bytes were accepted, but the
application should stop producing until its on_drain callback runs.

HTTP/2 also has receive flow control:

    $tx->auto_consume(0);
    $tx->consume($bytes_processed);

These functions belong to the HTTP engine, not the framework stream.

## Adapter code

The runnable Linux::Event example has a framework Stream subclass that
owns one Unblock::HTTP2::Server. It maps on_data(), on_eof(), on_error()
and on_drain() to input(), input_eof(), transport_error() and
resume_output().

Three host methods carry output in the other direction:

    unblock_send($bytes)
    unblock_finish()
    unblock_abort($reason)

That is all an ordinary Perl adapter should need. Do not write an
extra want_write()/output() loop when using transport => $self.

The example's second subclass contains application behavior, so the
adapter can be reused for unrelated applications.

For detailed error, shutdown and ownership behavior, read:

    perldoc Unblock::HTTP2::Integration
