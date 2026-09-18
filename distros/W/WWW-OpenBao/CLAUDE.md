# CLAUDE.md

WWW::OpenBao — minimal Perl HTTP client for [OpenBao](https://openbao.org/) and HashiCorp
Vault, extracted from `HI::Daemon`. KV v2 read/write/list/delete, Kubernetes ServiceAccount
login, and a few `sys/*` bootstrap helpers. One file (`lib/WWW/OpenBao.pm`), Moo-based,
released to CPAN via Dist::Zilla `[@Author::GETTY]`.

Deliberately small: no caching, no lease renewal, no policy management. Growing that
surface is a maintainer decision, not a patch.

Consumers: `goldmine`, `hiplatform`, and `hi-proto` — which still carries a **vendored copy**
of this module rather than depending on the distribution. See the hazards section of the
house rules before changing behaviour.

## Delegation

Delegate behavior-relevant code to the right agent instead of touching it yourself —
principle and lane are in `.claude/rules/www-openbao-rules.md`.

| Task | Agent |
|---|---|
| Implement / refactor / debug behavior-relevant code | `www-openbao-worker` (default) |
| Write/extend tests | `www-openbao-test-writer` |
| Pre-release audit | `www-openbao-release-checker` |
| Write/maintain POD and README | `www-openbao-doc-writer` |

The agents carry their skills via `briefing.skills` (see `.claude/agents/`); the main agent
delegates rather than loading them. Skill sources live under `.claude/skills/` —
`www-openbao-core` (repo conventions) and `openbao-general` (the OpenBao/Vault HTTP API)
are owned here; the `perl-*` and `karr` skills are hardlinked from the shared repos.

## Commands

```bash
prove -lr t          # full test suite — offline by construction, no live server
dzil build           # build the distribution
dzil test            # test via Dist::Zilla
karr board           # work board for this repo
```

The suite never touches the network: `_http` is a lazy Moo attribute so tests can stub it.
A test that needs a running OpenBao does not belong in this distribution.
