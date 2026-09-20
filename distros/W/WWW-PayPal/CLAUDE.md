# WWW-PayPal

Perl client for the PayPal REST API. Scope is driven by two concrete use cases: one-off
product purchases (replacing legacy `Business::PayPal::API::ExpressCheckout`) and
recurring monthly subscriptions.

## Where the knowledge lives

Nothing about architecture, conventions or PayPal itself is repeated in this file — a
duplicated rule is a rule that will drift. Each of these has exactly one source of truth:

| Topic | Source |
|---|---|
| House rules, delegation lock, release permission, repo hazards | `.claude/rules/www-paypal-rules.md` (auto-loaded) |
| Distribution internals — layer split, operation tables, entity contract, how to add an API | skill `www-paypal-core` |
| PayPal's own domain model — flows, states, webhooks, idempotency, money rules | skill `paypal-integration` |
| The library as consumers see it — usage, migration from ExpressCheckout, gotchas | skill `perl-www-paypal` |
| Perl house style, Moo patterns | skills `getty-perl-core`, `getty-perl-moo` |
| Build, POD directives, `Changes`/`{{$NEXT}}`, version semantics, release workflow | skills `getty-perl-release-author-getty`, `perl-release-dist-ini` |

`paypal-integration` is deliberately library-agnostic and `perl-www-paypal` deliberately
contributor-agnostic, so both can be hardlinked into consuming projects on their own.
`perl-www-paypal` currently ships that way into `hiplatform` and `goldmine` — changing the
public API here means updating it, or those projects go stale silently.

## Delegation

Delegate behavior-relevant code to the right agent instead of touching it yourself — the
principle and the lanes are in `.claude/rules/www-paypal-rules.md`.

| Task | Agent |
|---|---|
| Implement / refactor / debug code under `lib/`, `examples/` | `www-paypal-worker` (default) |
| Write or extend tests in `t/` | `www-paypal-test-writer` |
| POD, `Changes`, the consumer skill | `www-paypal-doc-writer` |
| Pre-release audit (never releases) | `www-paypal-release-checker` |
| Payment/subscription flow design or review, webhooks, billing data model | `paypal-expert` |

The agents carry their skills via `briefing.skills` (see `.claude/agents/`); the main
agent delegates rather than loading them. Skill sources live under `.claude/skills/` —
most are hardlinks, so read the hazards section of the rules file before editing one.

`paypal-expert` is intentionally un-prefixed and knows nothing about this distribution's
internals: it is the PayPal *application layer* specialist, meant to be hardlinked into
any project that takes PayPal money, together with skill `paypal-integration`.

## Coordination

`karr` board in `refs/karr/*` — `karr list --compact`, `karr board`. Open work is seeded
there; new drift becomes a ticket rather than scope creep. GitHub issues on
`Getty/p5-www-paypal` are a separate universe — never touched without explicit
instruction.

## End-to-end demos

Both need real sandbox credentials and a browser; they are the only place a live PayPal
call is allowed (`t/` is strictly offline).

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

## Related

- [paypal-rest-api-specifications](https://github.com/paypal/paypal-rest-api-specifications) — upstream OpenAPI specs, source of truth for the operation tables
- [PayPal Orders v2](https://developer.paypal.com/docs/api/orders/v2/) · [Subscriptions v1](https://developer.paypal.com/docs/api/subscriptions/v1/)
