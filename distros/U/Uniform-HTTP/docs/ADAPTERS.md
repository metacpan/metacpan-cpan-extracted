# Uniform::HTTP Adapter Guide 0.06

## Distribution boundary

Framework adapters are separate CPAN distributions. `Uniform-HTTP` must not
depend on them, recommend them as hard prerequisites, or runtime-probe for an
installed framework.

Examples of appropriate distribution boundaries are:

```text
Uniform-HTTP-HTTPMessage
Uniform-HTTP-Mojo
Uniform-HTTP-PSGI
Uniform-HTTP-PAGI
Uniform-HTTP-Dancer2
Uniform-HTTP-Catalyst
Uniform-HTTP-LinuxEvent
```

Names are illustrative until each adapter distribution is designed and
released.

## Construction

Adapter selection is explicit. A caller imports or constructs the adapter for
the native type it already owns. Core modules never guess an adapter by
examining installed packages or object class names.

An adapter may use inheritance or delegation. Compliance is defined by method
behavior, not by `isa('Uniform::HTTP::Message')`.

## Required decisions

Every adapter must document these facts for requests and responses separately:

| Question | Required behavior |
| --- | --- |
| Is the native object live or snapshotted? | State whether later native mutations are visible. |
| Are mutations supported? | Report overall and per-section mutability; throw for a locked section. |
| Are all duplicate fields visible? | Reflect this in `headers_are_lossless()`. |
| Is original field-name spelling retained? | Reflect this in `headers_are_lossless()`. |
| Is inter-field order retained? | Reflect this in `headers_are_lossless()`. |
| Is the request-target exact? | Reflect this in `target_is_exact()`. |
| Is the complete body buffered? | Reflect this in `has_buffered_body()`. |
| Is message completeness known? | Return true, false, or `undef` from `is_complete()`. |
| Are trailers visible, empty, or unavailable? | Use trailer observations; unavailable is `undef`, not an empty list. |
| Are trailers lossless? | Report independently through `trailers_are_lossless()`. |
| Which sections are editable now? | Report `initial_is_mutable()`, `body_is_mutable()`, and `trailers_are_mutable()`. |
| Has the whole native message become immutable? | Return false from `is_mutable()` and every section capability. |

Capability methods report the current object state, not the adapter's best-case
behavior.

The portable contract requires adapters to report mutability and completeness.
It does not require them to provide methods that change those states. The
canonical Uniform classes have local `freeze()`, `freeze_initial()`,
`freeze_trailers()`, `mark_incomplete()`, and `mark_complete()` helpers, but an adapter normally derives state from its
native object instead.

## Header adaptation

Use the native API that exposes individual field occurrences when one exists.
Do not split a combined value on commas in an attempt to recreate occurrences.
Quoted strings, dates, and field-specific grammars make generic splitting
incorrect.

If the native representation canonicalizes names, groups fields, discards
order, or combines duplicates, expose the best semantic values available and
return false from `headers_are_lossless()`.

Setter operations must preserve the Uniform contract even when the native API
uses different names:

- `header($name, $value)` removes all native occurrences and installs one.
- `add_header($name, $value)` appends rather than replaces.
- `remove_header($name)` removes all occurrences.

If the native object cannot reliably perform every required mutation in a
section, report that section as immutable. A metadata setter must not send
headers, and a trailer setter must not finalize a stream.

## Trailer adaptation

Keep trailers separate from initial headers even if a native convenience API
combines them. Use the native trailer list, preserving occurrences and order.
If the source irreversibly merged them, do not try to guess which fields were
trailers. Report unavailable trailers and false header fidelity if the initial
section can no longer be recovered.

For an available list, the trailer getters and mutators mirror the header API.
`has_trailers()` is true when that list currently contains any fields. An empty
list returns zero from `trailer_count()` and `[]` from `trailer_values()`.
An unfinished live list may still gain fields later.

For an unavailable list, `trailer_count()`, `has_trailers()`, and all trailer
getters return `undef`, including `trailer_values()`. Report false from
`trailers_are_lossless()` and `trailers_are_mutable()`. This works for both a
framework that never exposes trailers and one that exposes them only at a
later event. Document which situation applies. A known lossy list may be
exposed with false fidelity instead of being hidden entirely.

No Uniform getter waits for trailer arrival. A read-only adapter may observe
new fields supplied by the native receiver: mutability describes what the
Uniform caller may change, not whether external receipt is finished.
`is_complete()` must include trailers, not just the body. It may still be true
when trailer data is unavailable because the framework discarded it.

Never turn the initial `Trailer` field into actual trailer values. Never move
trailer authentication or routing fields into the initial section. Field
legality, announcement, and version-specific framing remain sender/parser jobs.

## Request-target adaptation

Prefer an untouched native request-target or request URI byte string. Do not
parse and reserialize it merely for convenience.

For HTTP/2 and HTTP/3 requests carrying `:path`, expose those exact bytes
through `target()` when possible.

Ordinary CONNECT is the special case. It has `:authority` but no `:path`.
Map the exact source `:authority` bytes to `target()` as an authority-form
target and also expose them through `authority()`. This does not count as
reconstruction, so `target_is_exact()` may remain true. Do not invent a
scheme for ordinary CONNECT.

Extended CONNECT carries `:protocol`, `:scheme`, `:authority`, and `:path`.
Expose `:protocol` through `protocol()` and keep `:path` as the target. Do not
apply the ordinary CONNECT authority-target mapping just because the method is
CONNECT; the presence of protocol metadata distinguishes the extended form.
The protocol engine checks required fields and negotiation before adaptation.

When only decomposed gateway values exist, an adapter may reconstruct the best
available target, but `target_is_exact()` must be false. In particular, path
normalization, percent-escape normalization, authority reconstruction, and
query-string reconstruction can change authentication and signature inputs.

## Scheme and authority adaptation

Expose native scheme and authority metadata only when the source environment
actually represents those values. Do not synthesize them simply to make an
adapter look more complete.

Uniform intentionally does not require full URI-authority parsing. The core
contract treats authority as a minimally checked byte string. An HTTP/2,
HTTP/3, framework, or application adapter remains responsible for any stricter
rules imposed by its own protocol or native API.

## Protocol and version adaptation

Expose an actual Extended CONNECT protocol-name token through `protocol()`.
An absent token is `undef`. If the framework hides this metadata, report
`undef` and document that limitation; do not advertise faithful Extended
CONNECT support. Do not infer it from Upgrade or specialize for WebSocket,
CONNECT-UDP, or WebTransport.

A sender validates protocol-specific field combinations and required settings.
These checks are not performed by creating a canonical Request. Copying
pseudo-fields into the ordinary header list is not a valid substitute for the
corresponding metadata properties.

Expose the received HTTP version when known. For outgoing neutral objects,
choose a sending version in the surrounding operation; no change to the
application's `version => undef` or frozen state is necessary.

## Body adaptation

Only expose `body()` when the entire body is already resident as a scalar.

For a PSGI input handle, PAGI body callback, Mojo content stream, evented
connection, or other incremental source, return false from
`has_buffered_body()` and do not consume it. The surrounding application can
buffer deliberately and create a canonical message when that tradeoff is
appropriate.

A response adapter must not invoke a responder, writer, drain callback, or
framework finalization operation from any Uniform method.

## Mutation and native commitment

`is_mutable()` is true when at least one of the three sections is editable.
It is false when none is. Each section capability is a boolean describing the
Uniform mutation operations that are currently allowed. After initial headers
are committed, `initial_is_mutable()` must be false even if the body buffer or
trailers can still change. A streaming-only body that cannot be replaced as a
complete scalar reports false from `body_is_mutable()`.

This refines the 0.03 all-or-nothing contract. Consumers that used
`is_mutable()` as permission for a particular setter should now query that
section. An adapter supporting only all-or-nothing mutation can return the
same native boolean for all three section capabilities. It still reports
trailer mutation false if its native API cannot implement trailer writes.

The canonical freeze helpers are not portable adapter methods and must not
be implemented by committing a response or sending its headers. Adapters can
simply observe native state, without offering those helpers at all.

Do not silently copy on mutation unless the adapter type is explicitly
documented as a snapshot adapter. A caller must be able to know whether it is
changing the native message or a detached Uniform value.

## Fast path

`Uniform::HTTP::FastPath` is not part of the adapter contract.

ABI version 1 works only with exact canonical Uniform message classes. Adapters
and subclasses use the portable methods in this guide and must not imitate
canonical private storage to opt into the fast path.

The optional native header added in 0.06 follows the same rule. It is compiled
by XS consumers; Uniform::HTTP remains pure Perl. See [Native FastPath](NATIVE-FASTPATH.md)
for construction, inspection, compatibility, and ownership rules.

## Framework checklist

The same contract applies to each target, but these are the likely pressure
points:

| Target | Primary adapter concern |
| --- | --- |
| `HTTP::Request` / `HTTP::Response` | Header canonicalization, grouping, and message-owned content. |
| Mojolicious | Native content buffering and response commitment. |
| PSGI / Plack | Environment-derived target fidelity and non-scalar input. |
| PAGI | Asynchronous body delivery must remain outside `body()`. |
| Dancer2 | Framework request/response lifetime and mutation boundary. |
| Catalyst | Context ownership and response commitment. |
| Linux::Event::HTTP | Keep connection, transaction, progress, and protocol handoff outside messages. |
| HTTP/2 or HTTP/3 engines | Preserve ordinary and Extended CONNECT, separate trailers, and message completeness. |

These concerns do not justify framework-specific exceptions in the core
contract. They are the reason the capability methods exist.

## Conformance tests

An adapter test suite should verify at minimum:

- ASCII case-insensitive lookup
- first-occurrence behavior of `header()`
- array-reference behavior of `header_values()`
- exact indexed header and trailer behavior and independent fidelity reporting
- unavailable trailers versus known empty trailers
- incomplete live trailer lists versus complete messages
- late native trailer arrival through a read-only view
- no implicit body reads
- truthful request-target fidelity
- exact ordinary and Extended CONNECT mapping when applicable
- truthful scheme and authority exposure
- truthful completeness and per-section mutability, including a locked body
- chainable successful mutations
- exceptions for mutation of each immutable section
- byte semantics without encoding guesses
- no transport or framework lifecycle side effects from Uniform methods

Tests should cover native representations containing multiple `Set-Cookie`
occurrences because generic comma handling frequently corrupts that field.

## Updating a 0.03 adapter

Add `protocol()` (and its setter if initial metadata is editable), the trailer
API, and the three section mutability observations. No new inheritance is
needed. Native APIs that discard trailers must use the unavailable behavior;
returning empty arrays would silently erase a meaningful distinction. A 0.03
adapter does not become 0.04-conforming just because it can wrap a 0.04 object.

Informational responses should each be exposed as a Response. Keep their
ordering and association with a final response on the transaction API. Likewise,
represent WebSocket, CONNECT-UDP, or WebTransport handshake data through the
normal Request/Response interface; expose tunnel and session operations outside
Uniform. See [the standards audit](MODERN-HTTP-AUDIT.md).
