# Uniform::HTTP Message Contract 0.02

Status: release contract for version 0.02.

## Purpose

The Uniform HTTP message contract gives application code one small semantic
interface across HTTP clients, servers, gateways, frameworks, middleware, and
test doubles.

It describes HTTP messages. It does not describe a socket, connection,
transaction, stream, framework context, parser, serializer, or retry operation.

The canonical `Uniform::HTTP::Request` and `Uniform::HTTP::Response` classes
implement this contract. An adapter may implement it through delegation and is
not required to inherit from a Uniform class.

## Common methods

Every message provides:

```perl
$message->version
$message->header($name)
$message->header_values($name)
$message->header_count
$message->header_name($index)
$message->header_value($index)
$message->body
$message->has_buffered_body
$message->is_complete
$message->is_mutable
$message->headers_are_lossless
```

A mutable message also provides these setter forms and mutators:

```perl
$message->version($version)
$message->header($name, $value)
$message->add_header($name, $value)
$message->remove_header($name)
$message->body($bytes)
```

Every successful mutator returns the receiving message. An adapter that reports
false from `is_mutable()` must throw when any mutator is attempted.

## Request methods

A request additionally provides:

```perl
$request->method
$request->target
$request->target_is_exact
```

A mutable request provides:

```perl
$request->method($method)
$request->target($target)
```

`method()` is the case-sensitive HTTP method token.

`target()` is the request-target byte string used by HTTP semantics. It is not
a URI object. Origin-form, absolute-form, authority-form, and asterisk-form are
all representable.

`target_is_exact()` is true only when `target()` is the exact source value. An
adapter that reconstructs the target from path, query, host, scheme, or routing
state must return false.

## Response methods

A response additionally provides:

```perl
$response->status
$response->reason
```

A mutable response provides:

```perl
$response->status($status)
$response->reason($reason)
```

`status()` is an integer from 100 through 599.

`reason()` is a byte string or `undef`. Implementations must not synthesize a
reason phrase merely because a status is known.

## Version

`version()` returns a numeric HTTP version without an `HTTP/` prefix, such as
`1.0`, `1.1`, `2`, or `3`. It may return `undef` when the gateway or transport
does not expose a meaningful version.

Implementations must not silently default an unknown version to `1.1`.

## Header representation

HTTP field lookup is ASCII case-insensitive. `header($name)` returns the first
matching occurrence. `header_values($name)` always returns an array reference,
including an empty one when the field is absent.

Repeated values are never implicitly comma-joined. Joining is not generally
lossless because HTTP fields differ in whether comma combination is valid.

The indexed methods expose every field occurrence in message order:

```perl
for my $index (0 .. $message->header_count - 1) {
    my $name  = $message->header_name($index);
    my $value = $message->header_value($index);
}
```

An index beyond the end returns `undef`. A negative or non-integer index is a
programmer error.

On mutation, `header($name, $value)` replaces every matching occurrence with
one field. The replacement occupies the first matching position and uses the
spelling supplied to the mutator. If no occurrence exists, it is appended.
`add_header()` always appends one occurrence. `remove_header()` removes every
matching occurrence.

`headers_are_lossless()` is true only when all three properties are preserved:

- duplicate field occurrences
- inter-field order
- original field-name spelling

An adapter may still be useful when this returns false. The capability method
makes the loss explicit to proxies, signing code, diagnostics, and tests.

## Body representation

`body()` returns a scalar only when the complete body is already buffered in
the message representation. It returns `undef` when no body buffer is present.
An empty buffered body is represented by `body() eq ''` together with a true
`has_buffered_body()`.

Calling `body()` must never implicitly:

- read a socket or filehandle
- drain a PSGI or PAGI input source
- invoke a streaming callback
- wait on a Future or promise
- decode content coding or character encoding
- consume a body that another component must replay

Incremental body transfer belongs to the surrounding transport or transaction.

Canonical messages are complete detached values. For them, `is_complete()` is
true even when the body argument was omitted. An adapter may return false while
a native message is still being assembled, or `undef` when completeness cannot
be determined.

## Byte contract

Methods operate on Perl byte strings. Implementations reject values containing
characters outside the byte range instead of guessing an encoding.

Header names and methods are HTTP tokens. Header values and reason phrases
reject prohibited control bytes. Horizontal tab and bytes from 0x80 through
0xff remain representable. Request targets are nonempty and reject spaces and
control bytes.

This contract does not decode text, normalize URIs, parse cookies, split field
grammar, or apply content codings.

## Canonical constructors

```perl
my $request = Uniform::HTTP::Request->new(
    method  => 'POST',
    target  => '/items?draft=1',
    version => '1.1',
    headers => [
        [ 'Content-Type', 'application/json' ],
        [ 'X-Trace',      'one' ],
        [ 'X-Trace',      'two' ],
    ],
    body => $bytes,
);

my $response = Uniform::HTTP::Response->new(
    status  => 201,
    reason  => 'Created',
    version => '1.1',
    headers => [ [ 'Content-Type', 'application/json' ] ],
    body    => $bytes,
);
```

Requests require `method` and `target`. Responses require `status`. `version`,
`reason`, `headers`, and `body` are optional where applicable. No protocol
version, reason phrase, or response status is guessed.

The `headers` argument is an array reference of two-element name/value array
references. A hash is intentionally not accepted because it cannot represent
duplicate occurrences and does not state a wire-derived order.

Canonical objects report:

| Capability | Result |
| --- | --- |
| `is_complete()` | true |
| `is_mutable()` | true |
| `headers_are_lossless()` | true |
| request `target_is_exact()` | true |

## Authentication integration

`Uniform::HTTP::Auth->prepare_authentication()` may accept a `request` object
implementing the request contract. It reads `method()` and `target()`. It reads
`body()` only when `has_buffered_body()` is true.

Explicit `method`, `request_target`, and `entity_body` arguments override the
corresponding request values. Authentication does not make a request replayable
and does not own retry policy.

## Explicit exclusions

The contract does not include:

```text
send write respond receive parse serialize
socket connection transaction stream
pause resume drain cancel retry redirect
authentication retry request replayability
TLS HTTP/1 framing HTTP/2 stream HTTP/3 stream
event loop Future promise callback policy
PSGI writer PAGI body callback framework context
```

An adapter can expose native operations through its own API, but those
operations are not Uniform HTTP message methods.
