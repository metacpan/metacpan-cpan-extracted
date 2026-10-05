# Modern HTTP message audit

Reviewed 2026-10-04 for Uniform::HTTP 0.05. This records message-model decisions,
not a claim that Uniform validates or implements every protocol requirement.

The same message model applies to Uniform::HTTP 0.06. Its native header
adds an optional construction and inspection path without changing the model.

## Standards and decisions

The following documents were reviewed for concepts that affect the common
message model. The mapping to Uniform is this project's design decision.

| Source | Message representation in Uniform | Owned by surrounding implementations |
| --- | --- | --- |
| [RFC 9110](https://datatracker.ietf.org/doc/html/rfc9110), sections 5, 6, 9, 15, 16.7 | Control data, ordered fields, opaque content, separate trailers, token syntax, individual informational responses | Field-specific meaning, context validation, routing, authentication policy, exchange sequencing |
| [RFC 9111](https://datatracker.ietf.org/doc/html/rfc9111), sections 3.1, 3.3, 4 | Cache metadata remains fields; retained trailers stay separate; incomplete state is observable | Cache storage, freshness, revalidation, merging cached representations |
| [RFC 9112](https://datatracker.ietf.org/doc/html/rfc9112), sections 3.2, 6, 7.1.2 | Exact four request-target forms; body and trailers are separate data | Start-line parsing, transfer coding, chunk termination, framing and smuggling defenses |
| [RFC 9113](https://datatracker.ietf.org/doc/html/rfc9113), sections 8.1-8.5 | Decoded fields, pseudo-field metadata, exact path, ordinary CONNECT authority target | Pseudo-field order and required combinations, lowercase wire names, HPACK, streams, flow control, push |
| [RFC 9114](https://datatracker.ietf.org/doc/html/rfc9114), sections 4.1-4.6 | Same message model and ordinary CONNECT mapping as HTTP/2 | HTTP/3 frames, QPACK, control streams, QUIC, stream completion and push IDs |
| [RFC 8441](https://datatracker.ietf.org/doc/html/rfc8441), sections 3-5 | Generic protocol-name property plus scheme, authority, and path | Extended CONNECT enablement, WebSocket handshake policy and tunnel handling |
| [RFC 9220](https://datatracker.ietf.org/doc/html/rfc9220), section 3 | Same Extended CONNECT metadata for HTTP/3 | HTTP/3 negotiation and stream behavior |
| [RFC 9218](https://datatracker.ietf.org/doc/html/rfc9218), sections 5-7 | Priority is an ordinary field, retaining its bytes | Structured field interpretation, PRIORITY_UPDATE frames and scheduling |
| [RFC 9297](https://datatracker.ietf.org/doc/html/rfc9297), sections 2-3 | Capsule-Protocol remains an ordinary field; switching response is a response | Capsule parsing, datagram association, tunnel data and flow control |
| [RFC 9298](https://datatracker.ietf.org/doc/html/rfc9298), section 3 | `connect-udp` is a generic protocol token in Extended CONNECT; HTTP/1 Upgrade remains ordinary fields | URI-template expansion, proxy authorization, UDP and datagram context machinery |
| [WebTransport HTTP/2 draft 15](https://datatracker.ietf.org/doc/html/draft-ietf-webtrans-http2-15), section 3 | Extended CONNECT with `webtransport`, plus ordinary handshake fields | Sessions, capsules, streams, datagrams and their limits |
| [WebTransport HTTP/3 draft 16](https://datatracker.ietf.org/doc/html/draft-ietf-webtrans-http3-16), section 3 | Extended CONNECT with `webtransport-h3`; Origin and WT negotiation metadata remain fields | Session establishment, SETTINGS, QUIC extensions, streams, datagrams and session shutdown |

Both WebTransport documents are works in progress, not RFCs. The pinned
revisions were current in the IETF tracker on the review date. No draft
codepoint, header name, protocol token, or version is hardcoded in Uniform.

## API decisions

1. Add separate trailers with the same field fidelity as headers. An empty
   section and no trailer fields have the same message-level representation;
   wire-section presence belongs to framing.
2. Add `protocol` as an optional HTTP protocol-name token, without deriving it
   from HTTP/1 Upgrade. Avoid protocol-name-specific APIs or validation tables.
3. Preserve exact authority bytes for ordinary CONNECT and exact path bytes
   for Extended CONNECT. No URI object or unnecessary reconstruction is needed.
4. Add local section freezes plus observable section mutability. Full freeze
   remains a full data lock; completion stays independent. No callbacks or
   automatic network lifecycle actions are introduced.
5. Keep `version => undef` valid for application-created messages, including
   frozen objects. A sending operation can select its version separately.
6. Represent every informational response separately. A complete 103 object
   does not mean that the request's response sequence has finished.
7. Keep unavailable adapter trailers distinguishable from a known empty list.
   Fidelity, current visibility, editability, and completeness are separate.
8. Keep field-specific legality and whole-message wire validation at the
   sender/parser boundary. Generic byte syntax is checked locally; a valid
   object is not automatically a legal message in every HTTP version.

## Additional coverage

Conditional requests, ranges, content negotiation, caching directives, cookies,
content codings, digest/signature fields, authentication metadata, Origin,
Alt-Svc, and extension fields already fit the ordered field representation.
Their parsers and policies do not require more core message classes. A message
can represent a pushed request or response; associating them with a push ID
belongs to the protocol implementation.

A successful CONNECT can switch the surrounding operation to tunnel semantics.
Uniform stores the handshake messages; it does not claim that tunneled bytes
are HTTP content or that a message owns the tunnel lifetime. Protocol errors,
abort reasons, retryability, and transport-close events stay outside the object.

## Compatibility assessment

No new runtime dependency is needed. Uniform::HTTP::FastPath is an optional
implementer interface and does not change the message model. The 0.03 full-freeze behavior,
constructor defaults, targets, headers, body access, and authentication APIs
remain available. The intentional adapter-contract refinement is that
`is_mutable()` can now describe partial mutability; consumers needing to edit
one section check its specific capability. False still forbids every data
mutation. Existing 0.03 adapters require the new observations to claim 0.04
conformance; they need not acquire canonical lifecycle helpers.
