# CLAUDE.md

Repo-spezifische Hinweise für `WWW::Crawl4AI`. Die allgemeinen Perl-Regeln
(Module-Loading, Moo/Moose, `@Author::GETTY` Dist::Zilla, cpanfile-Versionierung,
Style) stehen im `getty-perl-core`-Skill (`.claude/skills/`) — die gelten hier
weiterhin. Bei jeder Klassifikations- oder Chain-Frage ist der Code die
Wahrheit, nicht die Doku: `lib/WWW/Crawl4AI/Detect.pm` und `Changes` zuerst.

## Delegation

Delegation und Hausregeln: `.claude/rules/crawl4ai-rules.md` (automatisch geladen).

| Task | Agent |
|---|---|
| Implementieren, Refactoren, Debuggen, Verhalten, Tests | `crawl4ai-worker` (Standard) |
| Commits, `Changes`, Karte → done, Release-Audit vor jedem `dzil release` | `crawl4ai-release-manager` |
| Eine URL live durch die Strategy Chain jagen, Attempt-Tabelle diagnostizieren | `crawl-chain-probe` |
| Skills, CONTEXT.md und ADRs gegen `lib/` auf Drift prüfen | `docs-drift-auditor` |
| Issues und PRDs auf dem karr-Board triagieren und labeln | `karr-triage` |

## Agent skills

### Issue tracker

Issues und PRDs werden mit **karr** (git-natives Kanban, Board in `refs/karr/*`)
verwaltet. See `docs/agents/issue-tracker.md`.

### Triage labels

Die fünf kanonischen Triage-Rollen sind als karr-Tags mit ihren Standardnamen
abgebildet. See `docs/agents/triage-labels.md`.

### Domain docs

Single-context: ein `CONTEXT.md` + `docs/adr/` im Repo-Root. See `docs/agents/domain.md`.
