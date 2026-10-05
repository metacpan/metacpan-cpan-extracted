# Private nghttp2 backend

Unblock::HTTP2 uses libnghttp2 through the private
`Unblock::HTTP2::_nghttp2` XS binding.

This file records the contract that private binding must continue to provide.
It is not a second public HTTP/2 API.

## libnghttp2 owns

libnghttp2 remains responsible for:

- HTTP/2 frame encoding and decoding
- HPACK
- stream and connection state validation
- SETTINGS state
- connection and stream flow control
- mandatory protocol responses

## The private binding exposes

The Perl layer needs:

- client and server session creation
- memory input and output
- frame, native header-block collection, DATA, invalid-frame, and stream-close callbacks
- request and response submission
- generic HEADERS submission
- DATA providers and resume
- trailers
- RST_STREAM
- SETTINGS submission and effective peer SETTINGS
- PING
- GOAWAY
- RFC 9218 PRIORITY_UPDATE
- stream half-close queries
- separate connection and stream receive-credit release

The binding returns protocol facts and owns the native HTTP/2 header boundary.
It does not make application policy decisions.

For exact canonical Uniform::HTTP messages, it uses the Uniform::HTTP 0.06
native C ABI. Outgoing objects are inspected directly in XS. Received initial
header blocks are validated in the binding and constructed directly as
canonical Uniform objects from native byte spans. Trailers are handed to Perl
once per completed block. The portable Perl path remains required for
subclasses and adapters.

## SETTINGS

Received SETTINGS identifier/value pairs are exposed to Perl so Unblock can
report changes with portable setting names.

Effective peer SETTINGS are queried from libnghttp2. The public layer uses
those values for features such as Extended CONNECT and peer stream limits.

## Receive flow control

Sessions disable automatic WINDOW_UPDATE.

Connection-level credit and stream-level credit are released separately.

This lets Unblock keep the shared connection moving while allowing one HTTP/2
stream to delay its own credit until the application has consumed body bytes.

## DATA providers

Streaming local bodies are supplied through deferred DATA providers.

The provider may pause when no body bytes are available and resume later when
the application writes more data.

Provider storage must not be freed while libnghttp2 is still using it. Cleanup
requested during a native callback is deferred until the active nghttp2 call
returns.

## Errors and resets

The stream-close callback must preserve the HTTP/2 error code.

Local reset submission must accept an explicit validated 32-bit error code.

Invalid non-DATA frames expose frame metadata and the nghttp2 validation error
for observation. libnghttp2 remains responsible for the actual RST_STREAM or
GOAWAY response.

The nghttp2 diagnostic logging callback is not application protocol state and
must not be routed through the public error API.

## Modern priorities

The backend must support:

```text
SETTINGS_NO_RFC7540_PRIORITIES
PRIORITY_UPDATE
```

The public layer sends PRIORITY_UPDATE only when the peer has enabled the RFC
9218 model.

## Portability

The private binding must continue to work with:

- Perl 5.16 and newer
- threaded and multiplicity Perl builds
- Linux
- macOS
- Strawberry Perl on Windows

Native callbacks that use Perl APIs must establish the correct interpreter
context.

The portable output path returns protocol bytes from
`nghttp2_session_mem_send` as a Perl byte string. The optional NativeABI can
instead pass each borrowed nghttp2 output window directly to a native transport
sink. The sink must consume or copy the window before returning. The binding
does not maintain a second transport send queue.

The optional NativeABI also accepts borrowed contiguous input windows. It must
never retain the caller's input pointer after the native input call returns.

The binding and external consumers use the installed
`Unblock/HTTP2/NativeABI/unblock_http2_native_abi.h` declaration so the public
header and compiled operation layout cannot silently drift apart.

## Reentrancy

Recursive `input()` or `output()` while libnghttp2 is already executing is
not allowed.

Connection or provider cleanup requested from inside a native callback is
deferred until the nghttp2 call unwinds.
