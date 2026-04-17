# WWW-PayPal

Perl client for the PayPal REST API. Scope is driven by two concrete use cases: one-off product purchases (replacing legacy `Business::PayPal::API::ExpressCheckout`) and recurring monthly subscriptions.

Build, test, POD conventions (`=attr`/`=method`/`=seealso`), release workflow, version-bump semantics and `Changes`/`{{$NEXT}}` handling are all inherited from the `[@Author::GETTY]` plugin bundle — see the **perl-release-author-getty** and **perl-release-dist-ini** skills. This file only documents what's specific to WWW::PayPal.

## HTTP debugging

```bash
perl -MLWP::ConsoleLogger::Everywhere examples/buy_demo.pl ...
```

Full request/response dump for any script that uses the default `LWP::UserAgent` transport.

## End-to-end Demos

```bash
cpanm Mojolicious

# One-off product purchase (Orders v2)
perl examples/buy_demo.pl \
    --client-id $PAYPAL_CLIENT_ID --secret $PAYPAL_SECRET

# Recurring subscription — first run auto-creates product + plan and prints IDs
perl examples/subscribe_demo.pl \
    --client-id $PAYPAL_CLIENT_ID --secret $PAYPAL_SECRET \
    --price 9.99 --currency EUR
# Re-run with --product-id and --plan-id to avoid re-creating them
```

## Structure

```
lib/WWW/PayPal.pm                         # Main client (Moo) — OAuth2, base_url, sandbox/live
lib/WWW/PayPal/Role/HTTP.pm               # OAuth2 token cache + JSON request helper
lib/WWW/PayPal/Role/OpenAPI.pm            # operationId dispatch with pre-computed operation tables
lib/WWW/PayPal/API/Orders.pm              # Checkout / Orders v2 (create/get/capture/authorize)
lib/WWW/PayPal/API/Payments.pm            # Payments v2 (captures, refunds, authorizations)
lib/WWW/PayPal/API/Products.pm            # Catalogs products (create/list/get/patch)
lib/WWW/PayPal/API/Plans.pm               # Billing plans (+ create_monthly convenience)
lib/WWW/PayPal/API/Subscriptions.pm       # Billing subscriptions (create/get/suspend/activate/cancel/capture)
lib/WWW/PayPal/Order.pm                   # Order entity (approve_url, payer_*, capture_id, fee_in_cent, total)
lib/WWW/PayPal/Capture.pm                 # Capture entity (id/status/amount/fee_in_cent, refund method)
lib/WWW/PayPal/Refund.pm                  # Refund entity
lib/WWW/PayPal/Product.pm                 # Product entity
lib/WWW/PayPal/Plan.pm                    # Plan entity (activate/deactivate/refresh)
lib/WWW/PayPal/Subscription.pm            # Subscription entity (approve_url, subscriber_*, next_billing_time, lifecycle)
examples/buy_demo.pl                      # Mojolicious::Lite demo for Orders flow
examples/subscribe_demo.pl                # Mojolicious::Lite demo for Subscriptions flow
t/load.t                                  # Module load
t/openapi.t                               # Operation dispatch, path param substitution, entity parsing
```

## API Resources

| Resource      | API Class                         | Entity Class               | Primary Use                |
|---------------|-----------------------------------|----------------------------|----------------------------|
| Orders        | `API::Orders`                     | `Order`                    | One-off purchase flow      |
| Payments      | `API::Payments`                   | `Capture`, `Refund`        | Captures + refunds         |
| Products      | `API::Products`                   | `Product`                  | Subscription setup (once)  |
| Plans         | `API::Plans`                      | `Plan`                     | Subscription billing cycle |
| Subscriptions | `API::Subscriptions`              | `Subscription`             | Per-user recurring flow    |

## Architecture — Design Decisions

### OAuth2 Token Caching

`Role::HTTP` fetches a bearer token via `POST /v1/oauth2/token` with Basic auth (client_id:secret), caches it in memory, refreshes 60s before PayPal's reported `expires_in`. The token exchange is pure server-to-server — no callback, no HTTPS requirement on the local host.

### operationId Dispatch via Pre-Computed Operation Tables

Each API controller has its own `openapi_operations` builder returning a hash:

```perl
{
  'orders.create'  => { method => 'POST', path => '/v2/checkout/orders' },
  'orders.capture' => { method => 'POST', path => '/v2/checkout/orders/{id}/capture' },
  ...
}
```

`Role::OpenAPI` provides `get_operation($id)` and `call_operation($id, path => {...}, body => {...})` which substitutes `{param}` placeholders and dispatches via `$self->client->request`.

**Why this way, not runtime codegen:** The pattern is inspired by `Langertha::Role::OpenAPI` (which parses the spec lazily and lets engines override with pre-computed data). io-k8s-style build-time codegen was explicitly rejected. The pre-computed hash gives us zero runtime parsing cost, no `OpenAPI::Modern` dependency, and hand-written controller methods that stay readable.

**To regenerate** when the upstream [paypal-rest-api-specifications](https://github.com/paypal/paypal-rest-api-specifications) spec changes: open the relevant OpenAPI JSON, extract `operationId → {method, path}` for each operation, and update the controller's builder by hand. (A future `maint/` script could automate this.)

### Entity Wrappers

Entity classes wrap raw decoded JSON and expose the fields actually needed by consumers. They hold a weak reference to the parent client so instance methods like `$order->capture` or `$sub->suspend` work without re-plumbing.

- `data` is kept writable so `refresh` / `capture` / `activate` etc. can update the object in place rather than forcing consumers to track a new reference.
- Only fields with real consumers get accessors. If a consumer (e.g. amigaevent migration) needs more, add a method here — don't re-expose raw JSON.

## Adding a New API

1. **Controller** at `lib/WWW/PayPal/API/Foo.pm`
   - `has client` (weak_ref)
   - `has openapi_operations` with the operationIds from PayPal's OpenAPI spec
   - `with 'WWW::PayPal::Role::OpenAPI'`
   - High-level methods (e.g. `create`, `get`, `list`) wrapping `call_operation`
   - `_wrap` helper returning the entity class
2. **Entity** at `lib/WWW/PayPal/Foo.pm`
   - `has _client` (weak_ref, `init_arg => 'client'`)
   - `has data` (rw, required)
   - Accessors for the fields consumers need; keep the raw `data` available
   - Instance methods (`refresh`, lifecycle) that delegate back to the controller
3. **Wire in** to `lib/WWW/PayPal.pm` with a `lazy` attr + builder
4. **Test** in `t/openapi.t`: operation lookup, path param substitution, entity parsing with a sample JSON payload

## Tech

- **Moo** for OOP (no Moose, no Moose dep chain)
- **LWP::UserAgent** for HTTP (no pluggable IO backend in v0.001 — can be added later à la WWW::Hetzner if async is needed)
- **JSON::MaybeXS** + `HTTP::Request` for request/response
- **Log::Any** for logging
- **MIME::Base64** for OAuth2 Basic auth header

## Related

- [paypal-rest-api-specifications](https://github.com/paypal/paypal-rest-api-specifications) — upstream OpenAPI specs (source of truth for operation tables)
- [PayPal Orders v2 reference](https://developer.paypal.com/docs/api/orders/v2/)
- [PayPal Subscriptions reference](https://developer.paypal.com/docs/api/subscriptions/v1/)
- `perl-www-paypal` skill — consumer-facing usage (for AIs working on projects that import `WWW::PayPal`)
- `perl-release-author-getty` / `perl-release-dist-ini` skills — build, test, POD, `Changes` and release workflow
- `perl-moo` skill — Moo patterns used throughout
