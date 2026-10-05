# CLAUDE.md

WWW::Authentik — synchronous Perl client for authentik: OIDC against an application
(discovery, JWKS, token verification, the token, userinfo, introspection, revocation and
device endpoints) plus the REST API v3 (applications, OAuth2 providers, scope mappings,
users, groups, tokens, flows, stages, bindings, brands, certificates, blueprints) with
repeatable `ensure_*` methods. A structural sibling of `WWW::Keycloak`, written
independently of it. Moo-based; released to CPAN via Dist::Zilla `[@Author::GETTY]`.

Async twin: `p5-net-async-authentik` (`Net::Async::Authentik::*`), same API surface with
`_f` suffixes returning Futures — keep them in sync.

**Phase 1 is built** against authentik 2026.8.3. The design is
`docs/superpowers/specs/2026-10-04-www-authentik-design.md` (approved), the plan
`docs/superpowers/plans/2026-10-04-www-authentik-phase-1.md`. Phase 2 and 3 are listed in
section 10 of the spec; further work is on the karr board.

## Modules

- `WWW::Authentik` — facade: `base_url`, optional `application` (slug) and `token`; lazy
  `oidc` and `api` sharing one `LWP::UserAgent`. `default_ua` sets `max_redirect => 0` and
  `send_te => 0`; authentik hangs on every second request announcing the TE token.
- `WWW::Authentik::OIDC` — per application: discovery, JWKS, `verify_token`, the token
  endpoint, introspection, revocation, the device flow, `authorization_url`.
- `WWW::Authentik::API` — the REST API v3: basic operations, `resolve` for names, and the
  `ensure_*` methods, which return `{ object, changed }`.
- `WWW::Authentik::Diff` — comparison without I/O; lists are sets.
- `WWW::Authentik::Role::HTTP` — `build_request` / `read_response` / `send_request`.
- `WWW::Authentik::Error` — base; `::Validation`, `::Network`, `::API`.

## Delegation

Delegate behavior-relevant code to the right agent instead of touching it yourself —
principle and lane are in `.claude/rules/www-authentik-rules.md`.

| Task | Agent |
|---|---|
| Implement / refactor / debug behavior-relevant code | `www-authentik-worker` (default) |
| Write/extend tests | `www-authentik-test-writer` |
| Commits, `Changes`, card → done, pre-release audit | `www-authentik-release-manager` |
| Write/maintain POD | `www-authentik-doc-writer` |

The agents carry their skills via `briefing.skills` (see `.claude/agents/`); the main
agent delegates rather than loading them. Skill sources live under `.claude/skills/`.

## Commands

```bash
prove -lr t          # full test suite (recursive; live tests skip by default)
dzil test --all      # including the author and release tests
dzil build           # build the distribution

# the live suite, against a throwaway authentik from t/authentik/
AUTHENTIK_LIVE_TEST=1 AUTHENTIK_URL=http://127.0.0.1:9000 AUTHENTIK_TOKEN=... prove -lv t/90-live-authentik.t
```

`LICENSE` is committed, not generated at build time; re-run `dzil genlicense` and
`git add LICENSE` after changing license, holder or year in `dist.ini`.
