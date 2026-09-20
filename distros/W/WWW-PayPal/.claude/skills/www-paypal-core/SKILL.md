---
name: www-paypal-core
description: Load before editing the WWW::PayPal distribution itself — the controller/entity split, the operationId dispatch tables, the OAuth2 token cache, and the invariants to keep.
user-invocable: false
allowed-tools: Read, Grep, Glob
model: sonnet
---

# WWW::PayPal — internals

Perl client for the PayPal REST API. Scope is driven by two concrete use cases:
one-off product purchases (replacing legacy
`Business::PayPal::API::ExpressCheckout`) and recurring monthly subscriptions.
Nothing goes in that neither use case needs.

This skill describes the **inside** of the distribution. What consumers see is
skill `perl-www-paypal`; the PayPal domain model the library sits on is skill
`paypal-integration`.

## Layout

```
lib/WWW/PayPal.pm                    # client (Moo): credentials, base_url, sandbox, lazy API attrs, js_sdk_*
lib/WWW/PayPal/Role/HTTP.pm          # OAuth2 token cache + request() — the only place LWP is touched
lib/WWW/PayPal/Role/OpenAPI.pm       # get_operation / call_operation, {param} substitution
lib/WWW/PayPal/API/*.pm              # one controller per PayPal API — Orders, Payments, Products, Plans, Subscriptions
lib/WWW/PayPal/*.pm                  # entities — Order, Capture, Refund, Product, Plan, Subscription
t/load.t                             # module load
t/openapi.t                          # operation lookup, path substitution, entity parsing from sample payloads
examples/buy_demo.pl                 # Mojolicious::Lite demo, Orders flow
examples/subscribe_demo.pl           # Mojolicious::Lite demo, Subscriptions flow
```

Three layers, strictly: **client** (auth + transport) → **controller** (one per
API, owns the operation table and the high-level methods) → **entity** (wraps one
decoded JSON object). A layer never reaches past its neighbour.

## Invariant 1 — no runtime code generation, no spec parsing

Each controller carries its own `openapi_operations` builder: a plain hash from
`operationId` to `{ method, path }`, optionally `content_type`.

```perl
{
  'orders.create'  => { method => 'POST', path => '/v2/checkout/orders' },
  'orders.capture' => { method => 'POST', path => '/v2/checkout/orders/{id}/capture' },
}
```

`Role::OpenAPI` resolves `{param}` placeholders from the `path` argument and
dispatches through `$self->client->request`. A missing placeholder croaks by
design — a silently unsubstituted path would hit PayPal with a literal `{id}`.

The pattern comes from `Langertha::Role::OpenAPI` (lazy spec parsing, engines
override with pre-computed data); here only the pre-computed half is kept. This
buys zero runtime parsing cost, no `OpenAPI::Modern` dependency, and controller
methods that stay readable.

**Build-time codegen (io-k8s style) was considered and rejected.** Do not
reintroduce it, and do not add a runtime spec loader "just for the missing
operations". When the upstream
[paypal-rest-api-specifications](https://github.com/paypal/paypal-rest-api-specifications)
spec changes, open the relevant OpenAPI JSON, extract `operationId → {method,
path}`, and update the builder by hand. Automating that belongs in `maint/`, not
in `lib/`.

## Invariant 2 — one transport, one token cache

`Role::HTTP` is the only module that knows about `LWP::UserAgent`,
`HTTP::Request`, or JSON encoding of a request body. It fetches the OAuth2
bearer token via `POST /v1/oauth2/token` with Basic auth
(`client_id:secret`), caches it in memory, and refreshes 60 s before PayPal's
reported `expires_in`. The exchange is pure server-to-server — no callback, no
HTTPS requirement on the local host.

`request()` croaks on non-2xx with PayPal's own `message` /
`error_description` when the body parses as JSON, falling back to the status
line. Controllers must not swallow that croak to return undef; a failed API call
is an exception, not a null result.

There is deliberately **no pluggable IO backend** (unlike `WWW::Hetzner`). If
async is ever needed, that is a design change with its own decision — not
something to sneak in behind a role.

## Invariant 3 — entities expose fields that have a consumer

An entity wraps one decoded JSON object:

- `has _client` — `weak_ref => 1`, `init_arg => 'client'`, so `$order->capture`
  and `$sub->suspend` work without re-plumbing the client through call sites.
  Weak, because the client holds the controllers which produce the entities.
- `has data` — **`is => 'rw'` on purpose**: `refresh`, `capture`, `activate`,
  `cancel` update the object in place, so consumers never have to track a
  replacement reference. Do not "fix" this to `ro`.
- Accessors are thin readers over `data`, plus derived ones where the raw shape
  is hostile (`approve_url` from the HATEOAS `links` array, `fee_in_cent` as an
  integer, `capture_id` from the nested payments structure).

Only fields with a real consumer get an accessor. `->data` stays public for
everything else; when the same `->data->{...}` path shows up repeatedly across a
consuming project, that is the signal to add the accessor here — not to widen the
API pre-emptively.

## Adding an API

1. **Controller** `lib/WWW/PayPal/API/Foo.pm`: `has client` (`weak_ref`),
   `has openapi_operations` (lazy builder, operationIds from PayPal's spec),
   `with 'WWW::PayPal::Role::OpenAPI'`, high-level methods wrapping
   `call_operation`, and a `_wrap` helper returning the entity class.
2. **Entity** `lib/WWW/PayPal/Foo.pm` per invariant 3.
3. **Wire in** to `lib/WWW/PayPal.pm` as a `lazy` attribute with a builder that
   passes `client => $self`.
4. **Test** in `t/openapi.t`: operation lookup, path parameter substitution, and
   entity parsing against a sample payload.

High-level convenience methods (`orders->checkout`, `plans->create_monthly`) are
welcome where they collapse a known-good payload shape — but they must build on
`call_operation`, never bypass it, and the raw variant stays available.

## Tests

`prove -lr t/` — recursive, and the tests must stay **offline**: no live PayPal
call, no credentials, no network. Coverage comes from feeding recorded JSON
payloads into the entity classes and asserting the operation tables resolve.
A test that needs a token is not a unit test; it belongs in `examples/`.

## HTTP debugging

```bash
perl -MLWP::ConsoleLogger::Everywhere examples/buy_demo.pl --client-id … --secret …
```

Full request/response dump for anything using the default transport.

## Related

- Skill `perl-www-paypal` — consumer-facing API surface (what the library looks
  like from outside). Keep it in sync when the public API changes.
- Skill `paypal-integration` — PayPal's own domain model and flow rules.
- Skill `getty-perl-moo`, `getty-perl-release-author-getty`, `perl-release-dist-ini` — Moo
  patterns, POD conventions (`=attr`/`=method`/`=seealso`), release workflow.
