# Integrating Unblock::HTTP1 with an event loop

Unblock::HTTP1 has no required transport interface. An adapter only moves bytes
and reports EOF.

## Read path

When the transport receives bytes:

    $http->input($bytes);

Continue reading while $http->want_read.

If want_read becomes false because is_switched is true, stop feeding bytes to
the HTTP engine and hand take_remainder() to the next protocol.

If the transport reaches EOF:

    $http->input_eof;

Do not translate EOF into an empty input() call.

## Write path

Whenever the engine has bytes:

    while ($http->want_write) {
        my $bytes = $http->output;
        $transport->write($bytes);
    }

An adapter with a small write window can use output($maximum).

The engine's on_drain callback concerns the Unblock output queue. A transport
may have an additional high-water mark of its own.

## Timers

Unblock::HTTP1 does not create timers. Header deadlines, idle timeouts, connect
timeouts, keep-alive expiration, and application deadlines belong to the host.
The host can call close($reason) when one expires.

## TLS

TLS is outside the engine. Feed decrypted application bytes into Unblock and
send Unblock output through the TLS transport.

## Native borrowed input

The public byte API remains the correctness reference for every integration.

XS-backed transports can avoid the initial Perl input-buffer copy through
C<Unblock::HTTP1::NativeABI>. ABI version 1 accepts a borrowed native
C<(pointer, length)> window and reports the permanently consumed prefix.

The transport keeps ownership of the bytes. Unblock does not retain the native
pointer after the input operation returns.

C<INPUT_MORE> means the host must keep the unconsumed tail and present it again
with more contiguous input. C<INPUT_SWITCH> means HTTP has ended and the
unconsumed tail belongs to the next protocol.

A native adapter should create one ABI context per Client or Server connection
and keep it for the connection lifetime. It must fall back to C<input()> when
it cannot consume the advertised ABI version.

Native integrations can discover the installed ABI with:

    my $definition = Unblock::HTTP1::NativeABI::definition();
    my $include_dir = Unblock::HTTP1::NativeABI::native_include_dir();
    my $header_path = Unblock::HTTP1::NativeABI::header_path();
    my $header = Unblock::HTTP1::NativeABI::c_header();

C<definition()> reports the ABI version, structure size, provider, and
operations address. Consumers must check both the ABI version and structure
size before dereferencing operations.

The installed public header is:

    Unblock/HTTP1/NativeABI/unblock_http1_native_abi.h

C<c_header()> returns that same installed header text. The provider remains
transport-neutral: it does not know about file descriptors, epoll, readiness
watchers, or any framework-specific stream object.

Unblock::HTTP1 itself uses the Uniform::HTTP 0.06 native FastPath internally on
this route. Validated parser spans are copied directly into the final canonical
Uniform request or response object. The adapter does not need to know about
Uniform's native ABI and must not retain or manage any of those
object-construction details.
