# Integrating Unblock::HTTP1 with an event loop

Unblock::HTTP1 is an HTTP parser, serializer, and connection engine. It does not
own sockets, TLS sessions, or event loops.

**Start here:** the installed perldoc page Unblock::HTTP1::Integration contains
the full callback, ownership, shutdown, Upgrade/CONNECT, and backpressure
contract. The runnable examples are in examples/ and introduced in
docs/COOKBOOK.md. The Linux::Event server example lives in
examples/linux-event-server.pl; Linux::Event remains an optional dependency.

## The small host interface

Construct a Client or Server with the actual framework connection as host:

    $self->{http1} = Unblock::HTTP1::Server->new(
        transport  => $self,
        on_request => $on_request,
    );

That framework connection implements three methods:

    unblock_send($bytes)      # full-buffer acceptance into its output queue
    unblock_finish()          # close after queued output is fully sent
    unblock_abort($reason)    # immediate fatal close

The HTTP object stores a weak reference to its host. Callbacks must also
avoid creating strong reference cycles.

## Input from the framework

    network read        -> $http->input($bytes)
    clean read-side EOF -> $http->input_eof
    fatal socket error  -> $http->transport_error($reason)

The engine can deliver request or response callbacks synchronously while
parsing input. It can also generate output later when the application calls
respond(), write(), end(), or request().

## Output to the framework

With an attached host, output is delivered automatically through
unblock_send(). Do NOT use output() in this mode.

unblock_send() accepts the complete buffer or throws. Its return value
describes congestion only:

    true  = all bytes accepted; can accept more
    false = all bytes accepted; congested now
    undef = all bytes accepted; no backpressure information

If congested, the framework must call $http->resume_output when it can accept
more output. That also lets on_drain resume a paused streaming producer.

Once a buffer has been accepted by the framework, the framework owns that
buffer and the engine must not retransmit it. Thus unblock_finish() must
preserve and send every accepted byte before closing.

If unblock_send() throws or reports an unusable transport, the engine aborts
and calls unblock_abort().

Do not recursively call input() or input_eof() from a host send callback.

## Delayed response and half-close

For a fully parsed request, on_request may save the Transaction, then respond
later from a timer or application callback. The engine emits that response
without requiring a new socket-read event.

Read EOF after a complete request means the peer will send no more request
bytes. The server may still send the delayed response and then close
gracefully. An incomplete request at EOF is an HTTP error.

## Graceful shutdown

Stop the framework listener first, then call `$server->drain` on each
HTTP/1 server connection. The active request and response may finish, but
later pipelined requests are not admitted. The host must send all accepted
output before closing and enforce any grace-period deadline itself.

## Upgrade and CONNECT

The engine stops parsing HTTP on 101 Upgrade or successful CONNECT. Any bytes
already read after the handshake can be recovered from take_remainder().
Native borrowed input instead returns the unconsumed native window.

The server on_switch callback fires once the outgoing HTTP handshake has
been fully accepted by the attached framework host, even if the framework
has not finished writing it to the actual socket.

The next protocol owns the tail bytes. Unblock::HTTP1 does not create the
next protocol's socket or stream classes.

## Advanced manual mode

Without transport => $host, existing callers may still drive the engine:

    $http->input($bytes);
    while ($http->want_write) {
        $framework->write($http->output);
    }

Pick ONE owner of output per connection. Calling output() with a host
attached is a usage error.

## Native borrowed input

The optional NativeABI v1 accepts a borrowed (pointer, length) window and
reports the permanently consumed prefix. It does not retain the native
pointer after input processing.

INPUT_MORE means the caller must keep the unconsumed tail and present it
again with more contiguous bytes. INPUT_SWITCH means HTTP has ended and
the unconsumed tail belongs to the next consumer.

The public NativeABI discovery functions remain:

    Unblock::HTTP1::NativeABI::definition()
    Unblock::HTTP1::NativeABI::native_include_dir()
    Unblock::HTTP1::NativeABI::header_path()
    Unblock::HTTP1::NativeABI::c_header()

Consumers validate ABI version and struct size. The installed header is:

    Unblock/HTTP1/NativeABI/unblock_http1_native_abi.h

Uniform::HTTP 0.06 native FastPath remains in the engine. No framework
integration needs to build canonical Uniform objects manually.

## Timers and TLS

An integration owns all timers: idle timeouts, header deadlines, request
timeouts, and application deadlines. Unblock neither allocates event-loop
timers nor blocks for I/O.

TLS is also external. Feed decrypted HTTP bytes to input() and send HTTP
output through the TLS stream's own write queue.
