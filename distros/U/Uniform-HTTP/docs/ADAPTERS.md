# Uniform::HTTP Adapter Guide 0.02

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
| Are mutations supported? | Report through `is_mutable()` and throw when false. |
| Are all duplicate fields visible? | Reflect this in `headers_are_lossless()`. |
| Is original field-name spelling retained? | Reflect this in `headers_are_lossless()`. |
| Is inter-field order retained? | Reflect this in `headers_are_lossless()`. |
| Is the request-target exact? | Reflect this in `target_is_exact()`. |
| Is the complete body buffered? | Reflect this in `has_buffered_body()`. |
| Is message completeness known? | Return true, false, or `undef` from `is_complete()`. |
| Can the response already be committed? | Prevent mutation after commitment. |

Capability methods report the current object state, not the adapter's best-case
behavior.

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

If the native object cannot reliably perform any required mutation, the adapter
must report immutable rather than partially pretending to implement mutation.

## Request-target adaptation

Prefer an untouched native request-target or request URI byte string. Do not
parse and reserialize it merely for convenience.

When only decomposed gateway values exist, an adapter may reconstruct the best
available target, but `target_is_exact()` must be false. In particular, path
normalization, percent-escape normalization, authority reconstruction, and
query-string reconstruction can change authentication and signature inputs.

## Body adaptation

Only expose `body()` when the entire body is already resident as a scalar.

For a PSGI input handle, PAGI body callback, Mojo content stream, evented
connection, or other incremental source, return false from
`has_buffered_body()` and do not consume it. The surrounding application can
buffer deliberately and create a canonical message when that tradeoff is
appropriate.

A response adapter must not invoke a responder, writer, drain callback, or
framework finalization operation from any Uniform method.

## Mutation and commitment

An adapter around a mutable native object may return true from `is_mutable()`.
Once the framework commits or freezes the message, it must return false and all
Uniform mutators must throw.

Do not silently copy on mutation unless the adapter type is explicitly
documented as a snapshot adapter. A caller must be able to know whether it is
changing the native message or a detached Uniform value.

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

These concerns do not justify framework-specific exceptions in the core
contract. They are the reason the capability methods exist.

## Conformance tests

An adapter test suite should verify at minimum:

- ASCII case-insensitive lookup
- first-occurrence behavior of `header()`
- array-reference behavior of `header_values()`
- exact indexed header behavior and capability reporting
- no implicit body reads
- truthful request-target fidelity
- truthful completeness and mutability state
- chainable successful mutations
- exceptions for mutation while immutable
- byte semantics without encoding guesses
- no transport or framework lifecycle side effects from getters

Tests should cover native representations containing multiple `Set-Cookie`
occurrences because generic comma handling frequently corrupts that field.
