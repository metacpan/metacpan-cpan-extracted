---
name: perl-firecrawl
description: |
  Load when working on WWW::Firecrawl or Net::Async::Firecrawl — the Perl
  bindings for the Firecrawl v2 web-scraping/crawling API. Covers the
  self-hosted test instance (10.5.10.1:3002), client usage (sync + async),
  the WWW::Firecrawl::Error model (transport/api/job/scrape/page), strict /
  is_failure / retry policy, and flow-helper return shapes
  (crawl_and_collect, scrape_many, retry_failed_pages).
---

# Firecrawl (in this workspace)

Firecrawl is an open-source web scraping / crawling service. This workspace
contains Perl bindings for it and uses Firecrawl for live web retrieval in
several downstream projects.

## What's here

- **`p5-www-firecrawl/`** — `WWW::Firecrawl`: synchronous Perl v2 API client.
  Every endpoint has three flavours:
  - `foo_request(%args)` → builds an `HTTP::Request` (UA-agnostic)
  - `parse_foo_response($http_response)` → decodes JSON, dies on error
  - `foo(%args)` → sync convenience via `LWP::UserAgent`
- **`p5-net-async-firecrawl/`** — `Net::Async::Firecrawl`: `IO::Async` /
  `Net::Async::HTTP`-based async client returning `Future`s. All
  `WWW::Firecrawl` endpoints are exposed as Future-returning methods; flow
  helpers (`crawl_and_collect`, `batch_scrape_and_wait`, `extract_and_wait`,
  `scrape_many`) handle start→poll→collect patterns.

When writing new Perl code that needs Firecrawl, **use these modules**. Do
not hand-roll HTTP calls.

## Firecrawl deployment used for testing

There is a self-hosted Firecrawl instance reachable from this workspace at:

```
http://10.5.10.1:3002
```

No API key is required for the self-hosted instance. Passing one does no
harm. Both Perl clients default to cloud (`https://api.firecrawl.dev`); point
them at the self-hosted one via:

```perl
WWW::Firecrawl->new( base_url => 'http://10.5.10.1:3002' );
# or
Net::Async::Firecrawl->new( base_url => 'http://10.5.10.1:3002' );
# or environment:
$ENV{FIRECRAWL_BASE_URL} = 'http://10.5.10.1:3002';
```

For cloud usage, put the key in the workspace `.env` (gitignored):

```dotenv
FIRECRAWL_API_KEY=fc-...
```

Both clients read `FIRECRAWL_API_KEY` and `FIRECRAWL_BASE_URL` from the
environment by default.

## Quick CLI test

Shell smoke check against the self-hosted instance:

```bash
curl -sS -X POST http://10.5.10.1:3002/v2/scrape \
  -H 'Content-Type: application/json' \
  -d '{"url":"https://example.com","formats":["markdown"]}' \
  | jq -r '.data.markdown' | head
```

## Quick Perl test

```perl
use IO::Async::Loop;
use Net::Async::Firecrawl;

my $loop = IO::Async::Loop->new;
my $fc = Net::Async::Firecrawl->new( base_url => 'http://10.5.10.1:3002' );
$loop->add($fc);

my $doc = $fc->scrape( url => 'https://example.com', formats => ['markdown'] )->get;
print $doc->{markdown};
```

Or sync:

```perl
use WWW::Firecrawl;
my $fc = WWW::Firecrawl->new( base_url => 'http://10.5.10.1:3002' );
my $doc = $fc->scrape( url => 'https://example.com', formats => ['markdown'] );
```

## v2 Endpoint reference

Base URL: `<base>/v2/<path>`. Auth: `Authorization: Bearer <key>` (optional
for self-hosted).

| Endpoint | Purpose |
|---|---|
| `POST /scrape` | extract clean markdown from one URL |
| `POST /crawl` + `GET /crawl/{id}` | crawl a whole site (async job) |
| `POST /map` | quick URL discovery for a domain |
| `POST /search` | web search with optional full-page content |
| `POST /batch/scrape` + `GET /batch/scrape/{id}` | many URLs at once |
| `POST /extract` + `GET /extract/{id}` | structured extraction via schema/prompt |
| `POST /agent` + `GET /agent/{id}` | agentic web data gathering |
| `POST /browser/*` | interactive browser sessions |
| `GET /credit-usage`, `/token-usage`, `/queue-status`, `/activity` | monitoring |

Authoritative API docs: https://docs.firecrawl.dev/api-reference/v2-introduction

## Common gotchas

- Firecrawl's response shape nests the useful payload under `data` on single
  calls and under `data[]` on crawl/batch status. `WWW::Firecrawl`'s
  `parse_scrape_response` already unwraps the single-call `data`; flow
  helpers in `Net::Async::Firecrawl` hand back the full status hash.
- For crawls, pages arrive across **pagination chunks** (`next` URL in the
  status response when results exceed 10MB). `crawl_status_next` /
  `crawl_and_collect` handle this transparently.
- Target-level failures (site down, 404, Cloudflare block) arrive as
  `{success: true, data: {metadata: {statusCode: ..., error: ...}}}` — not
  as an exception. See the error-handling design spec in
  `docs/superpowers/specs/2026-04-18-firecrawl-error-handling-design.md` for
  how the clients will surface these.
- Firecrawl retries internally when proxies/target fail — don't stack our
  own retries on top of target-level failures; only retry 429/5xx *from
  Firecrawl itself*.

## When NOT to use this skill

- For questions about the upstream `firecrawl-cli` Node tool, or the
  `firecrawl/skills` repo's SDK-generation flow — those install things into
  your project and aren't part of this Perl workspace.
- For generic web scraping where a plain `LWP::UserAgent` fetch is enough —
  don't bring Firecrawl into the request path unless you actually need its
  proxy/JS-rendering/cleanup.
