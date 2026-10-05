# CLAUDE.md

WWW::Keycloak — synchronous Perl client for Keycloak: OIDC (discovery, JWKS, token verification, token and device endpoints) plus the Admin REST API (realms, clients, users), modelled on `WWW::Zitadel`. Moo-based; released to CPAN via Dist::Zilla `[@Author::GETTY]`.

Async twin: `p5-net-async-keycloak` (`Net::Async::Keycloak::*`), same API surface with `_f` suffixes returning Futures — keep them in sync. Phase 1 is built; design and plan are under `docs/superpowers/`.

## Delegation

Delegate behavior-relevant code to the right agent instead of touching it yourself —
principle and lane are in `.claude/rules/www-keycloak-rules.md`.

| Task | Agent |
|---|---|
| Implement / refactor / debug behavior-relevant code | `www-keycloak-worker` (default) |
| Write/extend tests | `www-keycloak-test-writer` |
| Commits, `Changes`, card → done, pre-release audit | `www-keycloak-release-manager` |
| Write/maintain POD | `www-keycloak-doc-writer` |

The agents carry their skills via `briefing.skills` (see `.claude/agents/`); the main
agent delegates rather than loading them. Skill sources live under `.claude/skills/`.

## Commands

```bash
prove -lr t          # full test suite (recursive; live tests skip by default)
dzil build           # build the distribution
dzil test            # test via Dist::Zilla
```

`LICENSE` is committed, not generated at build time; re-run `dzil genlicense` and
`git add LICENSE` after changing license, holder or year in `dist.ini`.
