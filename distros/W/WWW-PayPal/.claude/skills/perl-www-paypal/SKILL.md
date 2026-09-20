---
name: perl-www-paypal
description: Use when talking to PayPal from Perl — WWW::PayPal for one-off purchases (Orders v2), recurring subscriptions (Billing v1), refunds, and receiving/verifying webhooks.
user-invocable: false
allowed-tools: Read, Grep, Glob
model: sonnet
---

# WWW::PayPal

Perl client for the PayPal REST API. Use when the project imports `WWW::PayPal`, calls `$pp->orders`, `$pp->subscriptions`, `$pp->payments`, `$pp->webhooks`, or when migrating from `Business::PayPal::API::ExpressCheckout`.

## Client setup

```perl
use WWW::PayPal;

my $pp = WWW::PayPal->new(
    client_id => $ENV{PAYPAL_CLIENT_ID},    # required
    secret    => $ENV{PAYPAL_SECRET},       # required
    sandbox   => 1,                         # default: 0 (live)
);
```

OAuth2 `client_credentials` token is fetched lazily and cached in memory with auto-refresh. Token exchange is pure server-to-server — no callback URL needed.

## One-off product purchase (Orders v2)

Modern replacement for NVP `SetExpressCheckout` + `GetExpressCheckoutDetails` + `DoExpressCheckoutPayment`.

```perl
# 1. Create order
my $order = $pp->orders->create(
    intent         => 'CAPTURE',
    purchase_units => [{
        amount => { currency_code => 'EUR', value => '42.00' },
    }],
    return_url => 'https://example.com/paypal/return',
    cancel_url => 'https://example.com/paypal/cancel',
);

# 2. Redirect buyer's browser to:
my $approve_url = $order->approve_url;

# 3. On return from PayPal, capture (PayPal passes ?token=ORDER_ID in return_url)
my $captured = $pp->orders->capture($order->id);

# Fields available after capture (mirror legacy ExpressCheckout responses)
$captured->status;         # COMPLETED / APPROVED / ...
$captured->payer_email;    # replaces $resp->{Payer}
$captured->payer_name;     # replaces FirstName + LastName
$captured->capture_id;     # the capture ID, for later refunds
$captured->fee_in_cent;    # replaces $resp->{FeeAmount}
$captured->total;          # e.g. "42.00"
$captured->currency;       # e.g. "EUR"
```

`return_url` / `cancel_url` are *browser* redirects (not webhooks) — `http://localhost` works fine for local testing.

## Refunds

```perl
my $refund = $pp->payments->refund($capture_id,
    amount         => { currency_code => 'EUR', value => '10.00' },  # omit for full refund
    note_to_payer  => 'Sorry!',
    invoice_id     => 'INV-123',
);

$refund->id;       # refund ID
$refund->status;   # COMPLETED / PENDING / FAILED
$refund->amount;   # refunded amount

# Or via the capture entity:
$captured->refund(amount => { ... });
```

## Recurring subscriptions (Billing v1)

Three-step model: **Product** (what you sell) → **Plan** (how you bill) → **Subscription** (per user).

### Setup — once per deploy

```perl
my $product = $pp->products->create(
    name => 'VIP membership', type => 'SERVICE', category => 'SOFTWARE',
);

# Simple monthly fixed price
my $plan = $pp->plans->create_monthly(
    product_id => $product->id,
    name       => 'VIP monthly',
    price      => '9.99',
    currency   => 'EUR',
    trial_days => 7,       # optional free trial
    # total_cycles => 12,  # optional; 0/unset = infinite
);

# Full-control variant (custom cycles, setup fees, etc.)
my $plan = $pp->plans->create(
    product_id     => $product->id,
    name           => '...',
    billing_cycles => [ ... raw PayPal spec ... ],
    payment_preferences => { ... },
);
```

**Important:** Products and Plans are permanent PayPal objects. Create them once and persist the IDs — do NOT re-create on every app start, or you'll pollute the account. Freshly created plans may be in status `CREATED`; call `$plan->activate` or `$pp->plans->activate($id)` to make them usable.

### Per-user subscription flow

```perl
my $sub = $pp->subscriptions->create(
    plan_id    => $plan->id,
    return_url => 'https://example.com/paypal/sub/return',
    cancel_url => 'https://example.com/paypal/sub/cancel',
    subscriber => {                         # optional; PayPal pre-fills
        email_address => $user->email,
        name => { given_name => 'Alice', surname => 'Wonder' },
    },
    custom_id  => "user-$user_id",          # merchant reference — shows up in webhooks
);

# Redirect the buyer
my $approve_url = $sub->approve_url;
```

PayPal redirects back with `?subscription_id=I-...&ba_token=BA-...`. Fetch the current state:

```perl
my $sub = $pp->subscriptions->get($subscription_id);

$sub->status;                 # APPROVAL_PENDING / APPROVED / ACTIVE / SUSPENDED / CANCELLED / EXPIRED
$sub->subscriber_email;
$sub->subscriber_name;
$sub->plan_id;
$sub->custom_id;              # your merchant reference
$sub->next_billing_time;      # ISO-8601
$sub->last_payment_amount;    # e.g. "9.99"
$sub->last_payment_currency;  # e.g. "EUR"
```

Once `ACTIVE`, PayPal auto-bills on the plan's schedule — no per-cycle server action needed.

### Lifecycle

```perl
$sub->suspend(reason => 'User paused');
$sub->activate(reason => 'Resumed');
$sub->cancel(reason  => 'User cancelled');
# Or via the controller:
$pp->subscriptions->cancel($id, reason => '...');
```

All lifecycle methods require a `reason` (PayPal API quirk); library defaults to `'not specified'` if omitted. Each one also refreshes the local entity data.

### Capturing outstanding balance

For when PayPal's auto-bill fails and you want to retry manually:

```perl
$pp->subscriptions->capture($sub_id,
    amount => { currency_code => 'EUR', value => '9.99' },
    note   => 'Manual retry',
);
```

### Listing transactions

```perl
my $txs = $pp->subscriptions->transactions($sub_id,
    start_time => '2026-01-01T00:00:00Z',
    end_time   => '2026-12-31T23:59:59Z',
);
# $txs->{transactions} is the raw ArrayRef from PayPal
```

## Receiving webhooks

Registration and signature verification for incoming webhook events — order/capture
and subscription-lifecycle notifications delivered asynchronously, outside the
browser return-URL flow above. The domain-level event table and the full receiver
design rationale live in skill `paypal-integration`; this section is the library's
call surface.

### Registering an endpoint (once per environment)

```perl
use WWW::PayPal::WebhookEvents qw( :all );   # optional named constants; bare strings work too

my $webhook = $pp->webhooks->create(
    url         => 'https://example.com/paypal/webhook',
    event_types => [
        PAYMENT_CAPTURE_COMPLETED,
        BILLING_SUBSCRIPTION_ACTIVATED,
        PAYMENT_SALE_COMPLETED,
        'CUSTOMER.DISPUTE.CREATED',          # bare strings and constants mix freely
    ],
);
# store $webhook->id per environment — sandbox id != live id

$pp->webhooks->list;              # ArrayRef of WWW::PayPal::Webhook
$pp->webhooks->get($webhook_id);
$pp->webhooks->delete($webhook_id);

$webhook->url;
$webhook->event_names;            # ('PAYMENT.CAPTURE.COMPLETED', ...)
```

### Verifying an incoming event

```perl
my $ok = $pp->webhooks->verify(
    webhook_id        => $config->{webhook_id},   # from config — never hard-coded, never defaulted
    raw_body          => $raw_bytes,               # untouched bytes, captured before any parsing
    transmission_id   => $req->header('Paypal-Transmission-Id'),
    transmission_time => $req->header('Paypal-Transmission-Time'),
    transmission_sig  => $req->header('Paypal-Transmission-Sig'),
    cert_url          => $req->header('Paypal-Cert-Url'),
    auth_algo         => $req->header('Paypal-Auth-Algo'),
);
return $c->render(status => 400, text => 'bad signature') unless $ok;

my $event = decode_json($raw_bytes);
# dedupe on $event->{id}, then answer 2xx and process asynchronously
```

Critical rules — get any of these wrong and the receiver is either insecure or broken:

- **Always `verify()` before acting on an event, full stop.** An unverified receiver
  is a "grant everyone premium" endpoint — the payload alone proves nothing.
- **Capture the raw request body before anything parses it**, and pass those exact
  bytes as `raw_body`. In Mojolicious that's `$c->req->body`; in a Plack app, read
  `psgi.input` in full before any body-parser middleware touches it. A framework
  that decodes and re-serialises JSON changes the bytes, and re-serialised JSON
  never verifies — `verify` also croaks outright if `raw_body` is a reference.
- **`verify` returns a real boolean; `0` means reject, not retry.** `1` only on
  PayPal's `verification_status => SUCCESS`; a forged or tampered event comes back
  as ordinary HTTP 200 with `FAILURE`, which this method turns into `0` rather than
  a truthy string — never treat a non-empty status string as success. Only a
  transport error or a 4xx/5xx from PayPal itself croaks.
- **Dedupe on the event's own `id`** before doing any work. PayPal redelivers an
  event, with backoff, for up to ~3 days until you answer 2xx.
- **Answer 2xx fast; process asynchronously.** Slow handlers cause retries, retries
  cause duplicate processing — and event order is not guaranteed, so handlers must
  be commutative or re-fetch the object rather than assume what came before.
- **`webhook_id` is per environment.** Sandbox and live webhooks have different
  ids; keep it in config next to `client_id`/`secret` — never as a constant, and
  never defaulted.
- **`PAYMENT_CAPTURE_DECLINED` (v2) and `PAYMENT_CAPTURE_DENIED` (v1) are not
  aliases.** Orders v2 captures (the flow above) emit `DECLINED`; only legacy
  Payments v1 emits `DENIED`. Subscribe to the one matching your capture path.

## Migration from Business::PayPal::API::ExpressCheckout

| Legacy NVP                                   | WWW::PayPal                                    |
|----------------------------------------------|------------------------------------------------|
| `$api->SetExpressCheckout(%req)`             | `$pp->orders->create(...)`                     |
| `$response->{Token}` → redirect URL          | `$order->approve_url`                          |
| `$api->GetExpressCheckoutDetails($token)`    | `$pp->orders->get($id)`                        |
| `$api->DoExpressCheckoutPayment(%args)`      | `$pp->orders->capture($id)`                    |
| `$response->{Payer}`                         | `$order->payer_email`                          |
| `$response->{FirstName}` + `{LastName}`      | `$order->payer_name`                           |
| `$response->{FeeAmount}`                     | `$order->fee_in_cent` (cents, int)             |
| `$api->RefundTransaction(%args)`             | `$pp->payments->refund($capture_id, ...)`      |
| `Username` / `Password` / `Signature`        | `client_id` + `secret` (REST app credentials)  |
| `sandbox => 0|1`                             | `sandbox => 0|1` (same semantics)              |

Auth model differs: legacy NVP used API signatures; REST uses OAuth2 client credentials. Create a REST app at <https://developer.paypal.com> → grab `client_id` + `secret` → replace the three legacy creds.

## Entity JSON access

All entities keep the raw decoded JSON on `$entity->data`. Drop down to it if you need a field that isn't exposed:

```perl
$sub->data->{billing_info}{failed_payments_count};
$order->data->{purchase_units}[0]{shipping};
```

If you find yourself reaching into `->data` repeatedly for the same field across a project, add an accessor to the entity class rather than duplicating the path.

## Gotchas

- **`return_url` is a browser redirect, not a webhook.** No callback HTTPS/ingress needed for local testing. Webhook events (`BILLING.SUBSCRIPTION.*`, `PAYMENT.SALE.COMPLETED`, ...) arrive separately and asynchronously — see "Receiving webhooks" above.
- **PayPal amounts are decimal strings** (`"9.99"`), not floats. Pass strings, not numbers, or you risk precision surprises.
- **Products and Plans are permanent.** Cache their IDs; don't recreate them on each app restart.
- **Freshly created plans start in status `CREATED`** — activate them before creating subscriptions.
- **PayPal sends the order ID as `?token=` on the Orders return URL**, and as `?subscription_id=` on the Subscriptions return URL. The `ba_token` param is separate (billing agreement token) and usually ignorable.
- **OAuth callback confusion:** the OAuth2 client-credentials exchange is *not* a user-facing flow. There's no redirect URL, no callback, no HTTPS requirement on your host during token fetch.
