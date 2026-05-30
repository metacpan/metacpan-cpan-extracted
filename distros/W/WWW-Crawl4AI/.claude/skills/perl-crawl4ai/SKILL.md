---
name: perl-crawl4ai
description: WWW::Crawl4AI + Net::Async::Crawl4AI — Perl client and fallback orchestrator for the Crawl4AI Docker service. Covers the "crawler control plane" model, the visible strategy chain (plain→browser→stealth→cloakbrowser→proxy→callback), content classification via WWW::Crawl4AI::Detect, the three-flavour REST client, the Error model (transport/api/job/content), and the Attempt/Result history objects.
---

# Crawl4AI (in this workspace)

[Crawl4AI](https://github.com/unclecode/crawl4ai) is an open-source Docker
service that fetches a page (optionally with a real browser) and returns clean
Markdown. This workspace contains Perl bindings that wrap it as a **crawler
control plane**: Crawl4AI does the fetch + Markdown extraction; the Perl side
decides *policy*.

The key idea — and what makes this **not** "Firecrawl in Perl": fallback is not
hidden inside the service. Every attempt is modelled on the Perl side, so a
caller can see which backend won, what it cost, and — on failure — exactly why.

## What's here

- **`p5-www-crawl4ai/`** — `WWW::Crawl4AI`: synchronous client + orchestrator (Moo).
  - `WWW::Crawl4AI` — the facade: `->markdown($url)` / `->crawl($url)` runs the chain, returns a `WWW::Crawl4AI::Result`.
  - `WWW::Crawl4AI::Client` — UA-agnostic REST client, three flavours per endpoint:
    - `foo_request(...)` → builds an `HTTP::Request` (no I/O)
    - `parse_foo_response($res)` → decodes/normalizes (no I/O), dies on error
    - `foo(...)` → sync convenience via `LWP::UserAgent`, with retry
  - `WWW::Crawl4AI::Detect` — pure classification functions (no export).
  - `WWW::Crawl4AI::Strategy::*` — the chain links (Moo::Role consumers).
  - `WWW::Crawl4AI::Attempt` / `WWW::Crawl4AI::Result` — visible attempt history.
  - `WWW::Crawl4AI::Error` — error object (`is_transport`/`is_api`/`is_job`/`is_content`).
  - `bin/www-crawl4ai-doctor` — probe service reachability + print the active chain.
  - `bin/www-crawl4ai-test-url` — run the chain against one URL, print the attempt table.
- **`p5-net-async-crawl4ai/`** — `Net::Async::Crawl4AI`: `IO::Async` / `Net::Async::HTTP`
  async client returning `Future`s, including an async run of the same chain.
  Shares the pure building blocks (Request/Detect/Attempt/Result) with the sync
  client. **Load the `perl-net-async-crawl4ai` skill for the async specifics.**

When writing Perl that needs Crawl4AI, **use these modules**. Don't hand-roll
the REST calls or re-implement the fallback logic.

## The strategy chain

`markdown` / `crawl` walk applicable strategies in cost order and stop at the
first result `WWW::Crawl4AI::Detect` rates good:

| backend                 | cost class | what it does                                    | applicable when |
|-------------------------|------------|-------------------------------------------------|-----------------|
| `crawl4ai_plain`        | cheap      | headless `text_mode`                            | always          |
| `crawl4ai_browser`      | browser    | full JS render, wait for `networkidle`          | always          |
| `crawl4ai_stealth`      | stealth    | `enable_stealth` + random user agent            | always          |
| `crawl4ai_cloakbrowser` | stealth    | attach to CloakBrowser via `cdp_url`            | `cloakbrowser_url` set |
| `crawl4ai_proxy`        | paid       | stealth via `proxy_config`                      | `proxy_url` set |
| `external_callback`     | paid       | your coderef (last resort)                      | `callback` set  |

`fallback` selects the chain: `'auto'` (all applicable, default),
`'plain'`/`'none'` (Plain only), or an arrayref of backend names in explicit
order, e.g. `['crawl4ai_plain', 'crawl4ai_stealth']` (inapplicable names are
dropped).

A new strategy = a Moo class consuming `WWW::Crawl4AI::Strategy`, providing
`name`, `cost_class`, and `build_request($crawler, $url, %opts)` (or overriding
`crawl` if it doesn't go through Crawl4AI, like `Callback`).

## Content classification (the other half)

A crawl can be "200 OK" and still be junk. `WWW::Crawl4AI::Detect` is what
decides good vs. retry-with-a-bigger-hammer. Pure functions, nothing exported:

- `signals($page, %opt)` → `{ js_required, blocked, captcha, thin_html, http_error }`.
- `is_good($page, %opt)` → boolean.
- `why_failed($page, %opt)` → most-specific token: `captcha` > `bot_wall_detected`
  > `js_required` > `http_NNN` > `thin_content`, or `undef` when good.

Design rule baked in: **`blocked` is content-fingerprints only** (Cloudflare /
DataDome / "Just a moment" bodies), *not* HTTP status. Status lives on its own
axis (`http_error`), so a bare 403 reports `http_403` while a Cloudflare body
reports `bot_wall_detected`. Thin-content threshold is `$MIN_MARKDOWN` (default
500 chars), overridable per call (`markdown($url, min_markdown => N)`) or per
instance.

## The Result / Attempt history

`->crawl`/`->markdown` always returns a `WWW::Crawl4AI::Result`, never throws
for crawl failure:

```perl
my $r = $crawler->markdown('https://example.com');
$r->ok;            # did any strategy succeed?
$r->markdown;      # winning content (also $r->html)
$r->backend;       # crawl4ai_stealth / external_callback / ...
$r->cost_class;    # cheap / browser / stealth / paid
$r->final_url;
$r->why_failed;    # set when !ok
$r->attempts;      # arrayref of WWW::Crawl4AI::Attempt (what was tried, in order)
$r->attempts_json; # JSON-safe attempt history (markdown reduced to markdown_len)
```

On total failure `$r->ok` is false, `$r->error` is a `WWW::Crawl4AI::Error`
(type `content`), and `$r->attempts` holds the full trail.

## Running the service

There is no shared remote instance — run it locally. `examples/docker-compose.yml`
brings up Crawl4AI (and optionally a CloakBrowser CDP sidecar);
`docker-compose.proxy.yml` adds a proxy.

```bash
cd p5-www-crawl4ai/examples && docker compose up -d
# Crawl4AI REST on http://localhost:11235
```

Both clients default `base_url` to `$ENV{CRAWL4AI_URL}` →
`$ENV{CRAWL4AI_BASE_URL}` → `http://localhost:11235`. Optional bearer token via
`$ENV{CRAWL4AI_API_TOKEN}`. CloakBrowser via `$ENV{CLOAKBROWSER_CDP_URL}`, proxy
via `$ENV{CRAWL4AI_PROXY_URL}`.

```bash
# Is everything reachable? What's the active chain?
perl -Ilib bin/www-crawl4ai-doctor
# Run the chain against one URL and see every attempt:
perl -Ilib bin/www-crawl4ai-test-url https://example.com
```

## REST endpoints (Docker API, port 11235)

| Endpoint | Client method | Purpose |
|---|---|---|
| `POST /crawl` | `crawl` | synchronous crawl, returns page array |
| `POST /md` | `md` | markdown-only for one URL |
| `POST /crawl/job` + `GET /crawl/job/{task_id}` | `job_submit` / `job_status` | async job (status `PENDING`/`PROCESSING`/`COMPLETED`/`FAILED`) |
| `GET /health` | `health` | liveness |

Page results are normalized to a flat hash (`url`, `final_url`, `status_code`,
`markdown`, `html`, `raw_html`, `title`, `metadata`, `error`, `raw`) across the
several response shapes Crawl4AI has used across versions — `_result_list` and
`_normalize_page` in the client absorb that variation.

## Error model

`WWW::Crawl4AI::Error` with `type` ∈ `transport` / `api` / `job` / `content`:

- `transport` — Crawl4AI unreachable (599 / connection refused). Retried.
- `api` — non-2xx HTTP from Crawl4AI. Retried only for 429/502/503/504.
- `job` — a `/crawl/job` reported `FAILED`. Not retried.
- `content` — the chain exhausted all strategies (the `Result` carries this).

The Client retries transport + retryable statuses (default 3 attempts, backoff
`[1,2,4]`, honouring `Retry-After`). Don't stack your own retry on top.

## Common gotchas

- Getty house rules apply: `use Module;` (not `require`), 2-space indent,
  explicit `my ( $self ) = @_;`, `our $VERSION = '0.001'` per `.pm`,
  `JSON::MaybeXS` with `canonical`+`convert_blessed`, no trailing commas.
  Load the `perl-moo` skill for the OOP conventions.
- `markdown` is a plain string on old servers and a structured object on newer
  ones — `_extract_markdown` prefers `fit_markdown` → `raw_markdown` → … Don't
  assume a string.
- Don't confuse the facade `crawl` (runs the chain, returns a `Result`) with
  `WWW::Crawl4AI::Client->crawl` (single REST call, returns page array).
- `external_callback` is the escape hatch for paid scraping APIs — its coderef
  returns a page-shaped hashref (sync) or, under `Net::Async::Crawl4AI`, may
  return a `Future` of one.

## When NOT to use this skill

- For generic web scraping where a plain `LWP::UserAgent` fetch is enough —
  don't pull Crawl4AI (a browser-grade service) into the path unless you need
  JS rendering / stealth / proxy escalation.
- For the upstream Python `crawl4ai` library / its own CLI — that's not part of
  this Perl workspace.
- For async Future contracts and flow helpers — load `perl-net-async-crawl4ai`.
