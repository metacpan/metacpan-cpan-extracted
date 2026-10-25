---
name: perl-www-crawl4ai
description: "Use when fetching web pages from Perl via Crawl4AI — WWW::Crawl4AI, bot walls, captcha, thin content, why_failed tokens, or the Crawl4AI REST API on port 11235."
---

# Crawl4AI — the Perl bindings

[Crawl4AI](https://github.com/unclecode/crawl4ai) is an open-source Docker
service that fetches a page (optionally with a real browser) and returns clean
Markdown. Getty's Perl bindings wrap it as a **crawler control plane**:
Crawl4AI does the fetch + Markdown extraction; the Perl side decides *policy*.

The key idea — and what makes this **not** "Firecrawl in Perl": fallback is not
hidden inside the service. Every Attempt is modelled on the Perl side, so a
caller can see which backend won, what it cost, and — on failure — exactly why.

The domain vocabulary (Strategy Chain, Classification, Attempt, Result,
DeepCrawl, Action Endpoints) is defined in the repo's `CONTEXT.md` — use those
terms, not synonyms.

## What's here

- **`p5-www-crawl4ai`** — `WWW::Crawl4AI`: synchronous client + orchestrator (Moo).
  - `WWW::Crawl4AI` — the facade: `->markdown($url)` / `->crawl($url)` runs the chain, returns a `WWW::Crawl4AI::Result`.
  - `WWW::Crawl4AI::Client` — UA-agnostic REST client, three flavours per endpoint:
    - `foo_request(...)` → builds an `HTTP::Request` (no I/O)
    - `parse_foo_response($res)` → decodes/normalizes (no I/O), dies on error
    - `foo(...)` → sync convenience via `LWP::UserAgent`, with retry
  - `WWW::Crawl4AI::Detect` — pure Classification functions (no export).
  - `WWW::Crawl4AI::Strategy::*` — the chain links (`WWW::Crawl4AI::Strategy` role consumers).
  - `WWW::Crawl4AI::StrategyChain` — holds the strategy list; `add_strategy` / `remove_strategy` / `replace_strategy`.
  - `WWW::Crawl4AI::Attempt` / `WWW::Crawl4AI::Result` — visible attempt history.
  - `WWW::Crawl4AI::DeepCrawlIterator` — BFS frontier behind `deep_crawl` (`next` / `results` / `is_exhausted`).
  - `WWW::Crawl4AI::Request` — payload builder (`to_crawl_payload` / `to_md_payload`).
  - `WWW::Crawl4AI::Markdown` — `resolve_markdown_chain($md)` picks the best markdown variant.
  - `WWW::Crawl4AI::Error` — error object (`is_transport`/`is_api`/`is_job`/`is_content`).
  - `bin/www-crawl4ai-doctor` — probe service reachability + print the active chain.
  - `bin/www-crawl4ai-test-url` — run the chain against one URL, print the attempt table.
- **`p5-net-async-crawl4ai`** (sibling repo) — `Net::Async::Crawl4AI`: `IO::Async` /
  `Net::Async::HTTP` async client returning `Future`s, including an async run of
  the same chain. Shares the pure building blocks (Request/Detect/Attempt/Result)
  with the sync client. **In that repo, load its `perl-net-async-crawl4ai` skill
  for the async specifics.**

When writing Perl that needs Crawl4AI, **use these modules**. Don't hand-roll
the REST calls or re-implement the fallback logic.

## The Strategy Chain

`markdown` / `crawl` walk applicable strategies in cost order and stop at the
first result Classification rates good:

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
dropped). `fallback` is a constructor attribute, not a per-call option.

### Extending the chain

- New Strategy = a Moo class consuming `WWW::Crawl4AI::Strategy`, providing
  `name`, `cost_class`, and `build_request($crawler, $url, %opts)` (or
  overriding `crawl` if it doesn't go through Crawl4AI, like `Callback`).
- Swap or mutate the chain: pass `strategy_chain => $chain` to the constructor,
  override `_build_strategy_chain` in a subclass, or call
  `add_strategy` / `remove_strategy` / `replace_strategy` on the
  `StrategyChain` at runtime. Subclassing the chain's default class list goes
  via `chain_classes` (there is no `_build_default_strategies`).
- Classification is overridable: subclass `WWW::Crawl4AI` and override
  `classify_is_good` — the win/continue lever (default:
  `WWW::Crawl4AI::Detect::is_good`). Since 0.006 `_attempt_for` dispatches the
  decision through it, so an override actually changes which strategy wins and
  whether the chain escalates. `classify_signals` / `classify_why_failed` are
  overridable too, but they only shape the `signals` and `why_failed` *reported*
  on each Attempt, not the decision.

## Classification (the other half)

A crawl can be "200 OK" and still be junk. `WWW::Crawl4AI::Detect` decides
good vs. retry-with-a-bigger-hammer. Pure functions, nothing exported:

- `signals($page, %opt)` → `{ blocked, captcha, thin_html, http_error }`.
- `is_good($page, %opt)` → boolean.
- `why_failed($page, %opt)` → most-specific token: `captcha` >
  `bot_wall_detected` > `http_NNN` > `thin_content`, or `undef` when good.

**Content volume is the master signal** (since 0.005). A page fails only on:

- `thin_html` — markdown below `$MIN_MARKDOWN` (default 500 chars),
  overridable per call (`markdown($url, min_markdown => N)`) or per instance.
- `http_error` — HTTP push-back status, its own axis (a bare 403 reports
  `http_403`).
- `blocked` / `captcha` — the post-redirect **`final_url`** landed on a known
  WAF or captcha *challenge endpoint* (Cloudflare `/cdn-cgi/challenge`,
  DataDome `geo.captcha-delivery.com`, PerimeterX `/px/captcha`, reCAPTCHA /
  hCaptcha hosts). Structural evidence the request left the origin.

There are **no body-text, title, or HTML fingerprint heuristics** anymore — a
content-rich 200 page that merely *mentions* "enable JavaScript" or quotes
bot-wall phrases is a good scrape, full stop. There is also no `js_required`
signal: a thin JS shell simply reads `thin_content`. Don't reintroduce
fingerprint heuristics (see `Changes` 0.004/0.005 for the false-positive
history, e.g. the www.delphin.de regression).

Detect also carries the service-probing half: `probe_cloakbrowser($url)` and
`detect_proxy_env()` (used by `WWW::Crawl4AI->detect` and the doctor script).

## The Result / Attempt history

`->crawl`/`->markdown` always returns a `WWW::Crawl4AI::Result`, never throws
for crawl failure:

```perl
my $r = $crawler->markdown('https://example.com');
$r->ok;            # did any strategy succeed?
$r->markdown;      # winning content (also $r->html, $r->title, $r->status)
$r->backend;       # crawl4ai_stealth / external_callback / ...
$r->cost_class;    # cheap / browser / stealth / paid
$r->final_url;
$r->response_headers;
$r->why_failed;    # set when !ok
$r->attempts;      # arrayref of WWW::Crawl4AI::Attempt (what was tried, in order)
$r->attempts_json; # JSON-safe attempt history (markdown reduced to markdown_len)
$r->links;         # { internal => [...], external => [...] }
$r->urls;          # deduplicated link list (feeds DeepCrawl)
```

Further helpers: `attempt_count`, `internal_links` / `external_links`,
`to_hash` / `TO_JSON` (JSON-safe dump), and `Result->from_attempt($attempt)`
as the constructor the chain uses.

On total failure `$r->ok` is false, `$r->error` is a `WWW::Crawl4AI::Error`
(type `content`), and `$r->attempts` holds the full trail.

## DeepCrawl

```perl
my $results = $crawler->deep_crawl('https://example.com',
  max_pages  => 50,          # default 25
  max_depth  => 3,           # default 2; start URL is depth 0
  same_host  => 1,           # default true
  url_filter => sub { $_[0] !~ m{/login} },
  on_page    => sub { my ( $result, $depth ) = @_; ... },  # streaming/progress
  min_markdown => 200,       # remaining opts forwarded to each crawl()
);
```

BFS over each good page's `urls`, every page through the full Strategy Chain;
returns arrayref of `Result` in visit order. URLs are deduplicated with
fragments stripped. For pull-style iteration use
`WWW::Crawl4AI::DeepCrawlIterator` directly (`next` / `results` /
`is_exhausted`).

## Action Endpoints

One-shot operations that **bypass the Strategy Chain** — thin delegates to the
Client: `screenshot` / `pdf` (raw bytes), `html` (preprocessed string),
`execute_js` (page + js_result), `llm` (answer string), `token` (JWT hash),
plus `health` and `detect` (classify without crawling) and
`available_backends`.

## Running the service

There is no shared remote instance — run it locally.
`examples/docker-compose.yml` (in the `p5-www-crawl4ai` repo) brings up
Crawl4AI and optionally a CloakBrowser CDP sidecar;
`docker-compose.proxy.yml` adds a proxy.

```bash
cd examples && docker compose up -d
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
| `POST /screenshot`, `POST /pdf` | `screenshot` / `pdf` | raw bytes |
| `POST /html` | `html` | preprocessed HTML |
| `POST /execute_js` | `execute_js` | run JS snippets on the page |
| `GET /llm/{url}` | `llm` | ask the service's LLM about a URL |
| `POST /token` | `token` | JWT for token-protected deployments |

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

The Client retries transport + retryable statuses (`max_attempts` default 3,
`retry_backoff` `[1,2,4]`, honouring numeric `Retry-After`, `on_retry` hook).
Don't stack your own retry on top.

## Common gotchas

- In a Getty repo the house Perl rules apply on top — skills `getty-perl-core`
  (style, module loading, cpanfile) and `getty-perl-moo` (OOP conventions).
- `markdown` is a plain string on old servers and a structured object on newer
  ones — `WWW::Crawl4AI::Markdown::resolve_markdown_chain` prefers
  `fit_markdown` → `raw_markdown` → `markdown_with_citations` → `markdown`.
  Don't assume a string, and don't re-implement the preference order.
- Don't confuse the facade `crawl` (runs the chain, returns a `Result`) with
  `WWW::Crawl4AI::Client->crawl` (single REST call, returns page array).
- "callback" means two things: the `callback` attribute (your coderef) is the
  configuration; `external_callback` is the derived backend name. The coderef
  returns a page-shaped hashref (sync) or, under `Net::Async::Crawl4AI`, may
  return a `Future` of one.

## When NOT to use this skill

- For generic web scraping where a plain `LWP::UserAgent` fetch is enough —
  don't pull Crawl4AI (a browser-grade service) into the path unless you need
  JS rendering / stealth / proxy escalation.
- For the upstream Python `crawl4ai` library / its own CLI — that's not part of
  this Perl workspace.
- For async Future contracts and flow helpers — that's the sibling repo
  `p5-net-async-crawl4ai` and its skill.
