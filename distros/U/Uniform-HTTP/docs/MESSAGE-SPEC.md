# Uniform::HTTP Message Contract 0.04

Status: message contract for Uniform-HTTP 0.04.

## Purpose

Uniform gives HTTP implementations a small common interface for request and
response data. It covers initial control data, headers, an optional complete
buffered body, trailers, and observable message state.

The canonical `Uniform::HTTP::Request` and `Uniform::HTTP::Response` classes
implement this contract. Adapters may use delegation without inheritance.
No Uniform method sends data or changes a connection or framework lifecycle.

## Common methods

Every 0.04 message provides these observations:

```perl
$message->version
$message->header($name)
$message->header_values($name)
$message->header_count
$message->header_name($index)
$message->header_value($index)
$message->headers_are_lossless
$message->body
$message->has_buffered_body
$message->trailer($name)
$message->trailer_values($name)
$message->trailer_count
$message->trailer_name($index)
$message->trailer_value($index)
$message->has_trailers
$message->trailers_are_lossless
$message->is_complete
$message->is_mutable
$message->initial_is_mutable
$message->body_is_mutable
$message->trailers_are_mutable
```

These mutations are supported when the corresponding section is mutable:

| Section capability | Mutations |
| --- | --- |
| `initial_is_mutable()` | `version($value)`, `header($name, $value)`, `add_header($name, $value)`, `remove_header($name)`, request and response metadata setters |
| `body_is_mutable()` | `body($bytes)` |
| `trailers_are_mutable()` | `trailer($name, $value)`, `add_trailer($name, $value)`, `remove_trailer($name)` |

Every successful mutator returns the receiving message. A mutation on a
nonmutable section must throw, without changing data, even if its argument
would leave the value unchanged. Invalid arguments also throw.

`is_mutable()` is the overall capability: true means at least one section is
mutable, not necessarily all sections. False means no message data setter is
allowed. All three section capabilities must be false in that case. They
return booleans, not `undef`; an adapter unable to guarantee mutation must
report false for that section. `is_complete()` is independent and may return
true, false, or `undef` when unknown.

This is an explicit refinement of 0.03's all-or-nothing mutation model.
Existing canonical objects behave as before until a new section freeze is
used. Code handling partial mutability must check the relevant section before
writing. No 0.03 immutable object gains permission to mutate.

## Canonical lifecycle helpers

Canonical objects additionally provide:

```perl
$message->freeze_initial
$message->freeze_trailers
$message->freeze
$message->mark_incomplete
$message->mark_complete
```

These chainable methods are local conveniences, not adapter requirements.

- `freeze_initial()` locks version, initial headers, all request metadata
  (including `protocol`), and all response metadata. Body and trailers remain
  independently editable.
- `freeze_trailers()` locks the trailer fields, including an empty section.
- `freeze()` locks all represented message values, including body and trailers.
- All freezes are idempotent and irreversible through the public API. Applying
  a section freeze after full freeze never reopens anything.
- `mark_incomplete()` and `mark_complete()` change only completeness. Both
  remain usable after any freeze, as in 0.03. Neither freezes nor thaws data.

Canonical objects start complete and fully mutable, with empty header and
trailer lists and no body buffer. This suits application-created values. A
complete mutable object can still be edited; completeness does not describe
whether data has been sent or whether an exchange is finished.

An implementation assembling a received message can use:

```perl
my $message = Uniform::HTTP::Response->new(
    status  => 200,
    version => '3',
    headers => [ [ 'Content-Type', 'application/octet-stream' ] ],
)->mark_incomplete->freeze_initial;

# The HTTP implementation handles streaming outside this object.
# If it deliberately buffered the entire body, it can now install it:
$message->body($complete_body_bytes);
$message->add_trailer('Content-Digest', $digest_field_value);
$message->mark_complete->freeze;
```

While receiving, `has_trailers()` reports fields currently represented, not a
promise that no later fields will arrive. Mark complete only once the external
implementation knows the whole message has arrived, including any trailers.
If receipt fails, leave the object incomplete; error and cancellation details
belong to the surrounding operation. The helpers do not validate wire event
order. Freezing before expected trailers arrive deliberately prevents their
later insertion; use `freeze_initial()` for that situation.

| Canonical state | `is_mutable` | `initial_is_mutable` | `body_is_mutable` | `trailers_are_mutable` |
| --- | --- | --- | --- | --- |
| New | true | true | true | true |
| After `freeze_initial` | true | false | true | true |
| After both section freezes | true | false | true | false |
| After `freeze` | false | false | false | false |

Completeness is unchanged by every row transition. These states do not own
stream callbacks, framework commitment, or I/O.

## Request metadata

A request provides getters and, when initial data is mutable, setters for:

```perl
$request->method
$request->target
$request->scheme
$request->authority
$request->protocol
```

It also provides the read-only capability `target_is_exact()`.

`method()` is the case-sensitive HTTP method token. `target()` is a nonempty
request-target byte string, never a URI object. All target forms remain
representable without parsing, decoding, normalization, or reconstruction:

| Source | `target()` |
| --- | --- |
| HTTP/1 origin-form | Exact path and query, such as `/items?x=1` |
| HTTP/1 absolute-form | Exact target, such as `https://example.com/items?x=1` |
| HTTP/1 authority-form | Exact host and port, such as `example.com:443` |
| Asterisk-form | `*` |
| HTTP/2 or HTTP/3 request with `:path` | Exact `:path` bytes |
| Ordinary HTTP/2 or HTTP/3 CONNECT | Exact `:authority` bytes |
| Extended CONNECT | Exact `:path` bytes, not the authority |

Ordinary CONNECT has no `:path` or `:scheme`. Copying its `:authority` directly
into the authority-form target preserves the exact semantic target and is not
reconstruction. `scheme()` and `protocol()` are `undef` for that case.

`scheme()` and `authority()` are optional metadata. Uniform does not derive
them from `Host`, an absolute target, transport security, or each other. A
scheme uses URI scheme syntax. Authority is a nonempty byte string rejecting
controls, spaces, `/`, `?`, and `#`; it deliberately does not parse host syntax,
ports, userinfo, IP literals, or percent escapes.

`protocol()` is the optional protocol-name token represented by Extended
CONNECT's `:protocol`. It preserves the exact supplied spelling and accepts
any nonempty HTTP token, including future names. It is not an Upgrade field
list, a slash-separated protocol/version value, or the HTTP version. Passing
`undef` clears it. There is no inference from `Upgrade`, no registry lookup,
and no special behavior for particular tokens.

These properties are separate from ordinary header fields. The canonical
object validates individual value syntax, not combinations of method,
protocol, scheme, authority, target, version, or status. Applications can
assemble values in any setter order. A sender must check that the resulting
combination is valid for its selected protocol before sending it.

`target_is_exact()` is true only when the exposed target is an untouched source
semantic target. Reconstructing from separate path, query, host, scheme, or
routing values requires false. Canonical objects return true for the bytes the
caller supplied; copying a reconstructed target into one cannot recover lost
source fidelity. An adapter needing to report such a loss must retain its own
false capability rather than claiming a canonical copy restores it.

## Response metadata

A response provides `status()` and `reason()`, with setter forms when initial
data is mutable. Status is an integer from 100 through 599. Reason is an
optional byte string; Uniform never invents one from the status. Received
HTTP/2 and HTTP/3 responses normally have `reason => undef`.

Each informational response is a separate response object. For example,
`Response->new(status => 103)` can describe a complete Early Hints message
while the exchange still awaits its final response. Ordering 100, 103, and a
final response belongs to the HTTP implementation. So do version-specific
rules such as whether 101 can be sent, and body restrictions for HEAD, 1xx,
204, 304, or successful CONNECT. Status representation alone does not certify
a valid wire message.

## Version

`version()` is a numeric HTTP version string without `HTTP/`, for example
`1.0`, `1.1`, `2`, or `3`. The canonical syntax also accepts decimal forms such
as `2.0`; it does not normalize them.

Application-created messages may leave it `undef` and be used with any
supported HTTP version. An adapter selecting a sending version must not need
to stamp or unfreeze the application-owned object; that selection belongs to
the sending operation. Explicit versions are represented metadata, not a
negotiation command. The sender documents any constraints it applies.

Received messages should expose their actual HTTP version when known. Unknown
versions remain `undef`, never a guessed `1.1`.

## Header and trailer fields

Headers and trailers are separate ordered lists. Each preserves duplicate
occurrences, inter-field order, original name spelling, and value bytes.
Lookup uses ASCII case-insensitive names. No fields are joined, comma-split,
trimmed, unfolded, decoded, or moved between sections automatically.

`header($name)` and `trailer($name)` return the first matching value, or
`undef`. Their `_values` counterparts return a detached array reference of all
matching values in order, including `[]` for a known absent field.

The indexed methods enumerate occurrences from zero. Out-of-range indexes
return `undef`; negative or noninteger indexes throw. Counts include repeated
fields. Returned values and constructor inputs do not alias canonical storage.

For either section, the two-argument setter replaces all matching occurrences
with one at the first matching position, using the supplied name spelling.
An absent name is appended. `add_header` / `add_trailer` always append one
occurrence; `remove_header` / `remove_trailer` remove all matches.

`headers_are_lossless()` and `trailers_are_lossless()` independently report
fidelity of the represented source fields. Canonical lists return true.
Adapters must report false for a section if fields were dropped, combined,
reordered, renamed, or their value bytes changed. The source for HTTP/2 and
HTTP/3 is the decoded field list; compressed wire bytes are not represented.

`has_trailers()` means there is at least one currently represented trailer
field. Omitted trailers and an explicit empty list both return false and count
zero. The model does not record whether an empty wire trailer section existed.
It also does not infer trailers from the initial `Trailer` announcement field.

### Unavailable adapter trailers

A framework can hide or discard trailers. In that case the adapter must not
report a known empty section. It returns:

| Method | Unavailable trailer data |
| --- | --- |
| `trailer_count`, `has_trailers` | `undef` |
| `trailer`, `trailer_values`, `trailer_name`, `trailer_value` | `undef` |
| `trailers_are_lossless`, `trailers_are_mutable` | false |

This includes the distinction between `trailer_values()` returning `undef`
(unavailable) and `[]` (available, no matches). Argument validation still
applies. If a source exposes a lossy field list, enumerate that list and return
false from `trailers_are_lossless()` instead. If the source exposes live
incremental trailers, counts describe its current list; `is_complete()` tells
whether reception has finished. A complete message may still have unavailable
trailers when its framework discarded them.

### Field legality

Syntactic validity is not permission to send a field as a trailer. The sender
must know the field definition permits trailer use, check the selected HTTP
version and framing, and enforce context-specific restrictions. Uniform has
no static allowlist or blacklist that would prevent future field definitions.
It never makes late fields initial metadata or authentication input implicitly.
`Trailer`, `TE`, `Priority`, `Capsule-Protocol`, and extension fields remain
ordinary fields with interpretation owned by their consumers.

## Body and byte contract

`body()` returns the complete body only when already buffered as a scalar. It
returns `undef` when absent. `body => ''` is a present empty buffer and makes
`has_buffered_body()` true. Body buffering and whole-message completeness are
independent: the body can be buffered while trailers are still outstanding.

Calling `body()` never reads, waits, drains, invokes a streaming callback,
decodes content, or consumes a replay source. Supply the whole buffer with
`body($bytes)`; there is no partial-body append API. The surrounding HTTP
implementation owns incremental transfer and tunnel data. Capsule or WebSocket
bytes after a successful protocol switch are not automatically an HTTP body.

Values are byte strings. A byte-valued Perl scalar may be copied and downgraded
without changing its caller; values outside 0..255 are rejected instead of
encoded. Field names, methods, and protocol names are HTTP tokens. Field
values and reason phrases reject bytes 0..8, 10..31, and 127, while accepting
HTAB and high bytes. Targets reject spaces and controls. Body bytes are opaque.
No encoding, URI parsing, cookie parsing, or field-specific grammar is guessed.

## Constructors

```perl
my $get = Uniform::HTTP::Request->new(
    method => 'GET', target => '/items',
    scheme => 'https', authority => 'example.com',
);
my $connect = Uniform::HTTP::Request->new(
    method => 'CONNECT', target => 'example.com:443',
    authority => 'example.com:443',
);
my $extended = Uniform::HTTP::Request->new(
    method => 'CONNECT', protocol => 'websocket',
    scheme => 'https', authority => 'example.com', target => '/chat',
);
my $response = Uniform::HTTP::Response->new(
    status => 200,
    headers => [ [ 'Content-Type', 'text/plain' ] ],
    body => $bytes,
    trailers => [ [ 'Content-Digest', $digest_field_value ] ],
);
```

Request requires `method` and `target`. Response requires `status`. Optional
common arguments are `version`, `headers`, `body`, and `trailers`; optional
request arguments are `scheme`, `authority`, and `protocol`; response also
accepts `reason`. Unknown options throw. `headers` and `trailers` must be arrays
of two-element name/value arrays; hashes cannot express duplicate ordering.

## Authentication and scope

`Uniform::HTTP::Auth->prepare_authentication(request => $request, ...)` reads
method, target, and an available complete buffered body. Explicit `method`,
`request_target`, and `entity_body` arguments override those values. Trailer
fields do not replace initial authentication fields or create replayability.

Uniform owns no SETTINGS, GOAWAY, resets, stream IDs, flow control, HPACK,
QPACK, QUIC, datagrams, capsules, scheduling, ALPN, TLS, server-push lifecycle,
pooling, retry policy, redirects, or informational-response sequencing.
Native operations can exist on an adapter's separate API without becoming
portable Uniform methods. See [the standards audit](MODERN-HTTP-AUDIT.md) and
[adapter guide](ADAPTERS.md) for implementation boundaries.
