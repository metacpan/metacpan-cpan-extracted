# CLAUDE.md

This file provides project guidance for Claude Code and similar coding agents.
It is intentionally concise and focused on the repository itself.

## Project Overview

`WWW::VastAI` is a Perl client for the Vast.ai REST APIs.

The distribution covers:

- marketplace offer search
- instances and lifecycle operations
- templates
- volumes
- SSH keys and API keys
- current user and environment variables
- invoices
- serverless endpoints and workergroups

This is a Dist::Zilla distribution using `[@Author::GETTY]`.

## Architecture

The code is split into a few clear layers:

- `lib/WWW/VastAI.pm`
  Main client object. It owns configuration such as `api_key`, `console_url`,
  and lazy resource accessors like `offers`, `instances`, and `endpoints`.
- `lib/WWW/VastAI/API/*.pm`
  Resource controllers. These wrap named API operations and inflate response
  payloads into entity objects when appropriate.
- `lib/WWW/VastAI/*.pm`
  Entity classes such as `Offer`, `Instance`, `Template`, `Endpoint`, and
  `Workergroup`.
- `lib/WWW/VastAI/Role/OperationMap.pm`
  Central route table mapping operation names to HTTP method, base, and path.
- `lib/WWW/VastAI/Role/HTTP.pm`
  Request building, auth headers, JSON encode/decode, and response handling.
- `lib/WWW/VastAI/Role/IO.pm` and `lib/WWW/VastAI/LWPIO.pm`
  Transport abstraction plus the default `LWP::UserAgent` backend.

The operation map targets three API bases:

- `https://console.vast.ai/api/v0`
- `https://console.vast.ai/api/v1`
- `https://run.vast.ai`

## Common Tasks

When adding a new Vast.ai endpoint:

1. Add the operation to `lib/WWW/VastAI/Role/OperationMap.pm`.
2. Add or extend the matching controller in `lib/WWW/VastAI/API/*.pm`.
3. Add an entity class if the endpoint returns a stable object shape.
4. Add a lazy accessor in `lib/WWW/VastAI.pm` if this is a new resource group.
5. Add tests in `t/`.
6. Update POD and `README.md` if the public API changed.

## Tests

Normal unit tests:

```bash
prove -l t/
```

Dist::Zilla verification:

```bash
dzil test
dzil build
```

Optional live tests:

```bash
VAST_LIVE_TEST=1 prove -lv t/90-live-vastai.t
VAST_LIVE_TEST=1 VAST_LIVE_ALLOW_COST=1 prove -lv t/91-live-vastai-cost.t
VAST_LIVE_TEST=1 VAST_LIVE_ALLOW_COST=1 prove -lv t/92-live-vastai-volume.t
```

`VAST_LIVE_TEST=1` enables read-only live coverage.
`VAST_LIVE_ALLOW_COST=1` enables cost-incurring lifecycle tests.

## Documentation And Release Notes

- Keep runtime dependencies in `cpanfile`, not `dist.ini`.
- For user-visible distribution changes, add an unreleased entry under
  `{{$NEXT}}` in `Changes`.
- `README.md` should stay aligned with the main public workflow in the POD.

POD follows the `[@Author::GETTY]` conventions:

- use inline POD close to the code it documents
- use `=attr` and `=method` where appropriate
- do not write manual `NAME`, `VERSION`, `AUTHOR`, `SUPPORT`, or `COPYRIGHT`
  sections that PodWeaver generates

## Repository Metadata

- `AGENTS.md` is generated metadata and should not be edited directly.
- Project-specific agent and skill material lives under `.claude/`.
- Keep this file focused on the repository, not on generic agent behavior.
