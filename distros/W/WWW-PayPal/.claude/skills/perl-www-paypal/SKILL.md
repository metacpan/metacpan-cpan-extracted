---
name: perl-www-paypal
description: "WWW::PayPal — Perl client for the PayPal REST API. Covers one-off product purchases (Orders v2) and recurring monthly subscriptions (Billing Subscriptions v1), plus refunds."
user-invocable: false
allowed-tools: Read, Grep, Glob
model: sonnet
---

# WWW::PayPal

Perl client for the PayPal REST API. Use when the project imports `WWW::PayPal`, calls `$pp->orders`, `$pp->subscriptions`, `$pp->payments`, or when migrating from `Business::PayPal::API::ExpressCheckout`.

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

- **`return_url` is a browser redirect, not a webhook.** No callback HTTPS/ingress needed for local testing. Webhooks (`BILLING.SUBSCRIPTION.*`, `PAYMENT.SALE.COMPLETED`) are a separate optional feature not covered by WWW::PayPal directly.
- **PayPal amounts are decimal strings** (`"9.99"`), not floats. Pass strings, not numbers, or you risk precision surprises.
- **Products and Plans are permanent.** Cache their IDs; don't recreate them on each app restart.
- **Freshly created plans start in status `CREATED`** — activate them before creating subscriptions.
- **PayPal sends the order ID as `?token=` on the Orders return URL**, and as `?subscription_id=` on the Subscriptions return URL. The `ba_token` param is separate (billing agreement token) and usually ignorable.
- **OAuth callback confusion:** the OAuth2 client-credentials exchange is *not* a user-facing flow. There's no redirect URL, no callback, no HTTPS requirement on your host during token fetch.
