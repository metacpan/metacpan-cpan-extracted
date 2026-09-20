---
name: paypal-integration
description: Use when designing or reviewing a payment flow, subscription lifecycle, webhook receiver or billing data model, or when PayPal and the app disagree about a payment.
user-invocable: false
allowed-tools: Read, Grep, Glob
model: sonnet
---

# PayPal integration — the application layer

This skill is **library-agnostic on purpose**. It covers the model an application
must build *around* PayPal: which states exist, what has to be persisted, what
PayPal is authoritative for, and where naive implementations lose money. How to
make the actual REST calls in Perl is skill `perl-www-paypal`; that skill is not
needed to use this one.

## The one rule everything else follows from

**PayPal owns the money, the app owns the entitlement, and only webhooks are
authoritative.** The browser redirect back from PayPal is a *hint* that something
probably happened — a convenience for the UI. It is not a payment confirmation:
the buyer can approve and then close the tab, lose connectivity, or get a
timeout, and the payment still completes on PayPal's side. An integration that
grants access only in the return handler will silently under-deliver; one that
grants it only via webhook will feel slow. Do both:

1. **Return handler** — best-effort synchronous finish (capture / fetch state),
   updates the UI immediately. Must be idempotent, must tolerate being called
   never, once, or five times.
2. **Webhook receiver** — the authoritative writer of payment state.
3. **Reconciliation job** — periodically re-fetch anything stuck in a
   non-terminal state for longer than it should be. This is what catches the
   webhook that never arrived and the buyer who vanished mid-flow.

Neither 1 nor 2 alone is a complete integration.

## Two flows, two shapes

| | One-off purchase | Recurring subscription |
|---|---|---|
| API | Orders v2 | Billing Subscriptions v1 (+ Catalog Products, Plans) |
| Merchant setup | none | Product → Plan, created **once**, IDs persisted |
| Per-buyer object | Order | Subscription |
| Approval | redirect to `approve` link, PayPal returns `?token=<order-id>` | redirect to `approve` link, PayPal returns `?subscription_id=I-…&ba_token=BA-…` |
| Money moves | when *you* capture | automatically, by PayPal, on the plan's schedule |
| Terminal success | `COMPLETED` + a capture id | first `ACTIVE` then N payments over time |

The asymmetry that trips people up: for an order, **you** trigger the money. For
a subscription, PayPal does, forever, without asking — the app's only job after
activation is to *listen*.

### Order state machine

```
CREATED ──(buyer approves)──▶ APPROVED ──(you capture)──▶ COMPLETED
   │                              │
   └──(buyer cancels / abandons)──┴──▶ (stays, expires after ~3h/72h)
```

- `SAVED`, `PAYER_ACTION_REQUIRED` and `VOIDED` also exist; treat anything that
  is not `COMPLETED` as "not paid".
- With `intent: AUTHORIZE` there is an extra hop: authorize → (hold, honour
  period ~3 days, valid ~29 days) → capture. Only use it when you genuinely ship
  later; it doubles the number of states you must handle.
- An abandoned order costs nothing and needs no cleanup. Do not "cancel" orders.

### Subscription state machine

```
APPROVAL_PENDING ─(buyer approves)─▶ APPROVED ─▶ ACTIVE ⇄ SUSPENDED
                                                   │           │
                                                   └───────────┴──▶ CANCELLED / EXPIRED
```

- `ACTIVE` is the only state that means "entitled". `APPROVED` means the buyer
  said yes but PayPal has not started billing yet — it flips to `ACTIVE` on its
  own, usually seconds later, sometimes not.
- `SUSPENDED` is reached both by your own suspend call **and** by PayPal after
  the plan's `payment_failure_threshold` consecutive failed payments. The app
  cannot tell the two apart from the status alone — read
  `billing_info.failed_payments_count` before assuming a user paused voluntarily.
- `CANCELLED` is terminal and irreversible. Re-subscribing means a *new*
  subscription id. Never model "reactivate a cancelled subscription".
- Cancellation does **not** refund the running period and does not prorate.
  Decide explicitly whether entitlement ends immediately or at
  `billing_info.next_billing_time`, and write that decision down.

## What the application must persist

Minimum, per purchase:

| Field | Why |
|---|---|
| order id | to re-fetch state, to reconcile |
| capture id | **the only handle for a later refund** — an order id cannot be refunded |
| status + last check timestamp | reconciliation |
| gross amount + currency | invoice, not derived from your cart afterwards |
| PayPal fee | net revenue, bookkeeping; only known *after* capture |
| your own reference (`custom_id` / `invoice_id`) | maps the payment back to a user/cart |

Per subscription: subscription id, plan id, status, `next_billing_time`, your own
reference, plus a row per received payment. Store the **plan id you actually
used**, not "the current plan" — plans are immutable pricing snapshots and users
stay on old ones.

Two identifiers, two jobs, both set at creation time:

- **`custom_id`** — free-form merchant reference (`user-4711`). Echoed in API
  responses and webhooks. This is how a webhook finds the right row when your
  own ids are not in the payload.
- **`invoice_id`** — must be unique per merchant account. PayPal *rejects a
  second payment with the same `invoice_id`*, which makes it a server-side
  duplicate-payment guard. Use it when double payment is worse than a failed
  payment; do not use a value you might legitimately retry with.

## Idempotency

Three independent duplicate sources, three different defences:

1. **The buyer reloads the return URL.** Guard in your own code: look up the
   order row first, and if it already has a capture id, render success instead of
   capturing again. A second capture on a captured order fails with
   `ORDER_ALREADY_CAPTURED` (422) — recoverable, but only if you special-case it
   rather than showing the user an error.
2. **You retry a request after a timeout.** Send a `PayPal-Request-Id` header
   with a value you derive deterministically (e.g. the cart id). PayPal replays
   the original result instead of creating a second object. Essential on
   `orders.create` and any capture retry loop.
3. **PayPal redelivers a webhook.** PayPal retries any event you do not answer
   with 2xx, with backoff, for up to ~3 days. Dedupe on the event `id`, in a
   table with a unique index, before doing anything else with the event.

## Webhooks

Register a webhook per environment (sandbox and live have separate webhook ids)
and subscribe only to events you handle.

| Event | Meaning for the app |
|---|---|
| `CHECKOUT.ORDER.APPROVED` | buyer approved; safe to capture server-side |
| `PAYMENT.CAPTURE.COMPLETED` | **money received** — grant the one-off entitlement here |
| `PAYMENT.CAPTURE.DENIED` / `.DECLINED` | revoke / never grant |
| `PAYMENT.CAPTURE.REFUNDED` | refund happened (possibly from the PayPal web UI, not your code) |
| `PAYMENT.CAPTURE.REVERSED` | money taken back — chargeback outcome |
| `BILLING.SUBSCRIPTION.ACTIVATED` | **start the entitlement** |
| `BILLING.SUBSCRIPTION.UPDATED` | plan/quantity change went through |
| `BILLING.SUBSCRIPTION.SUSPENDED` | pause entitlement — check `failed_payments_count` for why |
| `BILLING.SUBSCRIPTION.CANCELLED` / `.EXPIRED` | end the entitlement |
| `BILLING.SUBSCRIPTION.PAYMENT.FAILED` | dunning: warn the user, count attempts |
| `PAYMENT.SALE.COMPLETED` | **a recurring payment was collected** — this, not a subscription event, is the renewal trigger |
| `CUSTOMER.DISPUTE.CREATED` | a human must look; freeze automated refunds for that transaction |

Receiver discipline:

- **Verify the signature** before trusting a byte. Either PayPal's
  `/v1/notifications/verify-webhook-signature` endpoint or local certificate
  verification — the payload alone is not authentication, and the endpoint is
  public. An unverified receiver is a "grant everyone premium" endpoint.
- Verification needs the **raw request body**. Frameworks that parse and
  re-serialise JSON break the signature. Capture the raw bytes before parsing.
- **Answer 2xx fast, process asynchronously.** Slow handlers cause retries,
  retries cause duplicates.
- Non-2xx is a legitimate answer for "I could not process this" — PayPal will
  retry. Never answer 200 to swallow an error you did not handle.
- Webhook order is **not** guaranteed. `ACTIVATED` may arrive after the first
  `PAYMENT.SALE.COMPLETED`. Handlers must be commutative or re-fetch the object.

## Money

- **Amounts are decimal strings, never floats.** `"9.99"`, not `9.99`. Any
  language that serialises a float into JSON will eventually emit
  `9.989999999999999` and PayPal will reject or, worse, accept it.
- **Decimal places are currency-dependent.** Most currencies take 2; `JPY` takes
  0 and PayPal rejects `"100.00"` for it. Do not hardcode two decimals.
- **Breakdowns must add up exactly.** If you send `items`, then
  `amount.breakdown.item_total` must equal the sum of `unit_amount × quantity`,
  and `amount.value` must equal the sum of the breakdown parts (item_total +
  tax_total + shipping − discount). One cent off → `UNPROCESSABLE_ENTITY`. Round
  once, at the point where you build the payload, and derive the total from the
  parts rather than sending two independently computed numbers.
- **Fees are known only after capture**, in `seller_receivable_breakdown`
  (`gross_amount`, `paypal_fee`, `net_amount`). Read the net from there; never
  recompute it from a fee percentage you believe is yours.
- **PayPal is not an invoice.** It moves money; it does not produce a legally
  valid invoice for your jurisdiction. Generate your own document from your own
  stored amounts.

## Refunds and disputes

- Refunds go against the **capture id**, not the order id, and are bounded by
  PayPal's refund window (180 days from capture at the time of writing — verify
  before relying on it for an old transaction).
- Partial refunds are allowed and repeatable up to the captured total; each one
  produces its own refund id. Store them.
- The refunded net is **not** simply the refunded gross: PayPal's fee treatment
  on refunds has changed over time and varies by account and region. Read the
  refund's own breakdown rather than assuming the fee comes back.
- A refund and a dispute are different mechanisms. Once
  `CUSTOMER.DISPUTE.CREATED` fires, refunding through the normal path may leave
  the dispute open or cause a double reversal. Route disputes to a human.
- Subscriptions: cancelling stops future billing, it does not refund the past.
  Refunds for past cycles are ordinary refunds against those payments' capture
  ids.

## Sandbox vs live

They are **two disconnected universes**, not a flag on one dataset:

- Separate credentials, separate accounts, separate webhook ids.
- **Product ids, plan ids, subscription ids and capture ids do not carry over.**
  A plan id from sandbox is a 404 in live. Anything created once per environment
  belongs in per-environment config, never in a code constant.
- The redirect targets differ (`sandbox.paypal.com` vs `paypal.com`); the JS SDK
  picks its environment from the client id, so a live client id with sandbox
  buyer accounts fails in a confusing way.
- Test the *unhappy* paths in sandbox, because they are the ones production will
  hand you: buyer cancels, buyer abandons after approval, payment fails and the
  subscription suspends, webhook arrives twice, webhook arrives out of order.
- Sandbox has a webhook simulator — use it to test the receiver's dedupe and
  signature verification without needing a real payment.

## Deciding the front end

- **Redirect flow** (server creates the order, browser goes to PayPal, comes
  back): fewest moving parts, works without JavaScript, easiest to reason about.
  Default choice for a server-rendered application.
- **JS SDK / Smart Buttons** (in-page popup): better conversion, shows Pay Later
  and local methods. Costs you a client-side integration, and `onApprove` runs in
  the *browser* — it is a UI callback, not proof of payment. The capture must
  still happen server-side, and the entitlement still comes from the webhook.

Either way, never let the client tell the server what was paid. The server
re-fetches the amount from PayPal or from its own cart record.

## Diagnosis quick table

| Symptom | Usual cause |
|---|---|
| `UNPROCESSABLE_ENTITY` on order create | breakdown does not add up, or a float leaked into an amount |
| `ORDER_ALREADY_CAPTURED` | return handler ran twice — add the pre-check |
| `RESOURCE_NOT_FOUND` on a valid-looking id | sandbox id used against live (or vice versa) |
| Subscription stuck in `APPROVED` | PayPal has not started billing yet; re-fetch, do not re-create |
| Subscription silently `SUSPENDED` | dunning: `payment_failure_threshold` reached |
| Webhook signature never verifies | body was re-serialised before verification, or wrong webhook id for this environment |
| Users report paying but have no access | entitlement granted only in the return handler |
| Amounts drift by a cent | rounding after building the payload instead of before |

## Related

- Skill `perl-www-paypal` — the Perl client (`WWW::PayPal`) that implements these
  calls. Everything above holds regardless of which client is used.
- <https://developer.paypal.com/api/rest/> — REST reference
- <https://developer.paypal.com/api/rest/webhooks/event-names/> — full event list
