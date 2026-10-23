# Engine contracts for ordinary Server reception

Historical design checkpoint (2026-10-17). These engine contracts were
implemented and merged before Unblock::HTTP 0.02 release preparation.
Date: 2026-10-17
Scope: perl-Unblock-HTTP1, perl-Unblock-HTTP2, perl-Unblock-HTTP3.
The branch and no-release instructions recorded during this milestone
no longer apply. See the current main-branch Handoff.md.

## First dependency milestone

Implement only the common receive-body and lifecycle primitives needed to
finish ordinary buffered and streamed Server requests. Keep each engine
independent of Unblock::HTTP and Unblock::WebSocket. No transport factory,
pooling, URL discovery, or WebSocket policy belongs in this change.

### Receive configuration

Use the existing HTTP3 vocabulary across all three engines:

    receive_body => 'buffered'   # or 'stream'
    max_buffered_body_bytes => $limit

Unblock::HTTP will explicitly request bounded buffered reception. Preserve
standalone engine defaults unless a separate breaking change is approved.
For buffered mode, define an explicit finite limit; never silently interpret
an unset or zero value as unlimited. Reuse H3's existing limit validation
where applicable. The upper-layer default size remains a documented tuning
choice, not a reason to change ordinary standalone engine behavior.

The engine owns the one receive accumulator. Count decoded body octets before
retaining each chunk. On overflow, fail the transaction and release retained
body bytes; never call the successful body-completion handler. H1 cannot reuse
an unread connection after this failure. H2/H3 must preserve unrelated streams.

Install the final body on the same Uniform message BEFORE mark_complete/freeze
and the body-completion callback. Preserve trailers and object identity.
An empty body is a complete empty buffer in buffered mode. Do not update the
full Message body on every chunk or maintain a second upper-layer accumulator.
Do not copy borrowed input unless retaining it past the call requires ownership.

### Per-transaction streaming selection

Provide this primitive on each real engine transaction:

    $tx->on_data(\&receive_chunk);

Register during the incoming-header callback, before any body delivery.
Registration selects streamed reception for that transaction and suppresses
full-body accumulation. The callback receives ($tx, $bytes), with payload bytes
only. The header callback must run first even when headers and the complete
body arrive in one input call. Empty and fragmented bodies follow the same order.
Reject attempts to change receive mode after body delivery has begun.

For this milestone, a registered data callback is fixed for the receive body;
do not introduce an implicit switch back to buffering. Existing low-level
on_body remains an engine interface, not an alias. Reject ambiguous simultaneous
per-transaction on_data and engine on_body delivery for the same transaction;
never deliver a chunk twice. The unified layer uses the new per-tx callback.

On servers, the current engine on_request remains the early header notification.
The unified layer maps it to application on_headers and maps on_request_end to
application on_request. The latter runs once after successful request completion,
including streamed requests. It does not wait for response completion.

On clients, the engine on_response remains the early header notification.
The unified layer will choose whether to expose it immediately (streaming) or
wait for successful response-body completion (buffered). Preserve informational
responses separately. A 404 or 500 response is not a transport error.

### Terminal notification

Provide a public per-transaction terminal callback:

    $tx->on_finish(\&finished);

Also accept on_finish among client request callback options, so it can be
installed before a request might finish synchronously. The callback receives
the real transaction, whose state/error accessors already describe the outcome.
Server code can register it during the header callback.

The callback runs once for complete, error, or cancelled, after the applicable
normal completion/error callbacks. Cancellation alone does not call on_error.
Receiving the last request byte is not terminal if the response is unfinished.
Commit terminal state before invoking callbacks. Reentrant cancel/close and
exceptions in earlier callbacks must not cause duplicate or missing terminal
notifications. Define exception propagation using the engine's existing policy.
Registration after the transaction is already terminal should fail explicitly
for this first contract; no surprise synchronous late notification.

## Tests required in each engine branch

- Default standalone behavior remains valid with no new options.
- Buffered body in one read, many reads, empty body, trailers, and exactly at
  the limit. Overflow by one byte and malformed/truncated body must not invoke
  successful completion or retain the accumulator.
- Headers and body in one read: on_data selection takes effect before the first
  byte callback. No full-body buffer is constructed in streaming mode.
- Buffered and streamed transactions coexist on multiplexed connections.
- Cancellation during headers, data, completion/error callbacks, and repeated
  cancellation; terminal notification occurs exactly once.
- Error callbacks that throw still permit deterministic terminal cleanup.
- Native and ordinary input paths have the same callback order and ownership.
- H2/H3 failure of one transaction does not fail unrelated streams.
- Existing response sugar, stream_body write/end, and transport congestion
  semantics remain intact.

Record tests and measured buffer ownership behavior. Do not assert zero-copy
or performance improvement without comparing the same workload before/after.

## Following dependency milestones, not included automatically

- A supported transaction_class constructor option for upper-layer subclasses
  providing WebSocket conveniences and stream => 1 translation. This must keep
  the same underlying transaction object and work with native construction.
- Public pause/resume mapped to bounded receive buffering and per-stream credit.
  H2 auto_consume/consume and H3 Body::Reader are starting primitives, but H3
  callback-mode Reader currently returns credit automatically after callbacks.
- A generic H1 successor consumer handling public and native input, remainder,
  EOF, errors, and writable events after the handshake boundary.
- Supported post-dispatch H2/H3 WebSocket flushing and pool-capacity/lifecycle
  notifications. Net::QUIC changes would require their own authorization.

These later items remain part of the overall design, but the first dependency
milestone should establish ordinary Server body/callback behavior before
introducing WebSocket protocol transitions.
