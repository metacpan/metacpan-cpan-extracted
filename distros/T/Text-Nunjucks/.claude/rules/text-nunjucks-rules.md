# Text::Nunjucks House Rules

The shared house rules come from skilletor — bundle `getty-cpan-dist@getty`: engineering
discipline, the delegation lock, the publish gate, karr coordination, CPAN release. They load
as `.claude/rules/.local.*.md`; if they are missing, run `skilletor sync` and publish nothing
until they load. This file adds what is true only here, and wins where it differs.

## What this repo is

A 1:1 Perl port of Nunjucks v3.2.4 — same templates, same context, same options →
byte-identical output and the same error messages. Read first: the upstream JS file and its
upstream test file, before any Perl. "I know how Nunjucks works" is the dangerous sentence here.

## Agent team

| Task | Agent |
|---|---|
| Find out where something is, how upstream does it, what is missing (read-only) | `text-nunjucks-scout` |
| Port / implement / refactor / debug behavior-relevant code | `text-nunjucks-worker` (default) |
| Port upstream test suites, grow the corpus, reproduce fidelity bugs | `text-nunjucks-test-writer` |
| Compare a ported module against its upstream file (read-only) | `text-nunjucks-fidelity-auditor` |
| POD, README, the prose of a decided ADR | `text-nunjucks-doc-writer` |
| Commits, `Changes`, card → done, pre-release audit | `text-nunjucks-release-manager` |

Porting: worker → fidelity-auditor → worker → done; no audit means "looks right" beats "is 1:1".
The fidelity-auditor is this team's reviewer. The main agent's lane also includes putting
`decision` tickets in front of the maintainer.

Behavior-relevant = `lib/`, `t/`, `xt/`, `maint/`, `cpanfile`, `dist.ini`; pure prose is not.

## Deviations from the house rules

- **Green runs report counts.** "Tests pass" is wrong if any were skipped or TODO — report those
  counts with every green run.
- **Respect `depends_on`.** An open `decision` blocks the ticket — take the rest or the decision
  first.
- **Upstream is mozilla/nunjucks.** Its GitHub tracker falls under the publish gate like ours. An
  upstream bug gets ported (ADR 0004) and noted in a karr ticket; reporting upstream is the
  maintainer's call.

## Hazards — locks here, mechanisms in `text-nunjucks-core`

- **Never port from memory** — ask the oracle, commit the probe as a corpus case.
- **`upstream/` may be absent** — then the oracle can't run; say the oracle check was NOT run.
- **`prove -lr t/`, never `prove -l t/`** — `t/upstream/` is a subdirectory the short form skips.
- **Expected values are generated, never typed** — `maint/corpus-regen` writes `expected`.
- **Open mappings are decided once, by ADR** — `decision` tickets need the maintainer, not a filter.

## With superpowers

A plan runs in this folder on this branch, no worktree, so the board stays here. Per task,
one after another: `text-nunjucks-worker` (a test task: `-test-writer`, docs: `-doc-writer`)
is told to skip the implementer prompt's commit step; `text-nunjucks-fidelity-auditor`
reviews the uncommitted `git diff`; then `text-nunjucks-release-manager` commits. Never
`general-purpose`: built-in agents get no briefing. Brainstorming and the plan stay with
the main agent. Upstream's tests are ported, not invented: "test first" here means the
ported upstream suite is in (as TODO) before the module is.

## Perl specifics — reference, don't restate

House Perl style lives in skills `getty-perl-core` / `getty-perl-moo` (module loading, class
patterns, cpanfile, Changes); the porting contract in `text-nunjucks-core`.
