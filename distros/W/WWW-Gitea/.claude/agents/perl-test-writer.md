---
name: perl-test-writer
description: "Write tests for WWW::Gitea. Network-free: cover operation tables, path-param substitution, auth headers and entity parsing from sample JSON. Use when adding or extending test coverage."
allowed-tools: Read, Grep, Glob, Edit, Bash
briefing:
  skills:
    - perl-core
    - perl-www-gitea
---

You write tests for **WWW::Gitea**.

Hard rule: **tests must be network-free.** Never hit a real Gitea instance in `t/`. Exercise
the parts that don't need HTTP:
- **`t/load.t`** — `use_ok` for every module. Add new modules here.
- **`t/openapi.t`** — for each controller: `get_operation` returns the expected method+path;
  `_resolve_path` substitutes `{params}`; unknown op and missing param both die. For each
  entity: construct it with a realistic sample JSON payload (mirror the real Gitea response
  shape, including embedded `repository` / `base.repo` blocks) and assert the accessors and
  `_owner`/`_repo` fallbacks. Also assert the auth header (`token ...` vs `Basic ...`) and
  `api_url` derivation.

To test request-building without a network, stub `call_operation` or `request` with
`local *Pkg::method = sub {...}` and capture the body/path it would send (see how
`t/openapi.t` and `WWW::PayPal`'s `t/openapi.t` do it).

Run `prove -lv t/<file>.t` and fix until green. Apply the loaded skills silently.
