# Integration

Unblock::HTTP2 does not own sockets, TLS, or an event loop.

A transport normally moves bytes between its connection object and an
Unblock::HTTP2 Client or Server.

## Portable path

The portable interface is:

```perl
$engine->input($bytes);

while ($engine->want_write) {
    my $bytes = $engine->output;
    last unless length $bytes;
    $transport->write($bytes);
}
```

This works with pure Perl and with any framework.

## Native path

XS-backed transports can use `Unblock::HTTP2::NativeABI`.

ABI version 1 has the same basic input lifecycle used by
`Unblock::HTTP1::NativeABI`:

```text
create
input
eof
destroy
```

HTTP/2 adds:

```text
output
want_read
want_write
```

Use:

```perl
my $definition = Unblock::HTTP2::NativeABI::definition();
my $include_dir = Unblock::HTTP2::NativeABI::native_include_dir();
my $header_path = Unblock::HTTP2::NativeABI::header_path();
my $header = Unblock::HTTP2::NativeABI::c_header();
```

The definition provides the ABI version, structure size, and address of the
native operations table. The other discovery methods expose the installed
header and its include directory.

A native consumer must check both `abi_version` and `struct_size` before
dereferencing the operations table.

An XS adapter should create one native context for each Client or Server and
keep it for the lifetime of that HTTP/2 connection.

## Input ownership

Native input receives a borrowed pointer and length.

The caller owns the input buffer. Unblock::HTTP2 does not retain the pointer
after the input call returns.

libnghttp2 keeps partial frame parsing state internally. A fragmented HTTP/2
frame can therefore be supplied as separate borrowed input windows.

## Output ownership

Native output calls a transport-provided sink with borrowed libnghttp2 output
bytes.

The sink must copy or write those bytes before returning. The pointer must not
be retained.

The sink can return the pause result after accepting a chunk. This stops the
current drain without losing that chunk. Resume output when the transport can
accept more data.

An event transport should normally append these chunks to its existing native
send queue. A sink callback is not intended to imply one network syscall per
nghttp2 chunk. The purpose of this path is to copy directly from nghttp2 into
transport-owned native storage instead of first building an intermediate Perl
output string.

## What stays in Unblock

Using the native transport ABI does not move HTTP/2 behavior into the adapter.

Unblock::HTTP2 still owns:

- HTTP/2 framing and HPACK through libnghttp2
- stream and connection state
- Uniform::HTTP construction
- flow control
- SETTINGS
- PING and GOAWAY
- resets
- trailers
- informational responses
- transaction lifecycle

The adapter only moves bytes and maps transport readiness.

## Fallback

The native ABI is optional.

If the adapter does not use XS, does not support ABI version 1, or does not
want the native path, use the normal `input()`, `output()`, `want_read()`,
and `want_write()` methods.
