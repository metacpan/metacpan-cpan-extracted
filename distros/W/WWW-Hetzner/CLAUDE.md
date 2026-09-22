# WWW::Hetzner

Synchronous Perl client for Hetzner's Cloud and Robot APIs. The architecture, resource
mesh, IO transport seam and test harness are documented in the `www-hetzner-core` skill —
not here.

## Delegation

Delegate behavior-relevant code to the right agent instead of touching it yourself — the
principle, the delegation lock and the release rule are in
`.claude/rules/www-hetzner-rules.md`.

| Task | Agent |
|---|---|
| Implement / refactor / debug behavior-relevant code | `www-hetzner-worker` (default) |
| Write/extend tests | `www-hetzner-test-writer` |
| Write/maintain POD | `www-hetzner-doc-writer` |
| Pre-release audit | `www-hetzner-release-checker` |

The agents carry their knowledge via `briefing.skills` (see `.claude/agents/`); the main
agent delegates rather than loading those skills itself. Skill sources live under
`.claude/skills/` — `www-hetzner-core` (this distribution), `getty-perl-moo`,
`getty-perl-release-author-getty`, `perl-release-dist-ini`, `kanban-issues-karr-cli`.

Coordination runs on the repo's `karr` board (`karr board`). Release is never run without
the maintainer's explicit go-ahead.
