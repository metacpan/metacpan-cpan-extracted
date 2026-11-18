# Text::Nunjucks

A **1:1 Perl port of [Nunjucks](https://mozilla.github.io/nunjucks/) v3.2.4** — same
templates, same context, same options → byte-identical output and the same error
messages as the JavaScript original. CPAN distribution `Text-Nunjucks`, Perl 5.40+, Moo.

Status: the template pipeline is ported and tested (Lexer, Nodes, Parser, Transformer,
Compiler, Runtime, Environment, base Loader, `is` tests). Not yet: the built-in filters,
globals, the file-system loader and the top-level `Text::Nunjucks` API. What is open and
in which order is on the karr board (`karr board`). Start there, not here.

## How "1:1" is enforced

- `maint/fetch-upstream` checks the pinned upstream tag out to `upstream/` (gitignored).
  Needs network + node. Run it first on a fresh clone.
- `maint/oracle.js` renders / lexes / parses cases with the real upstream. Its output is
  correct by definition (ADR 0004):
  `echo '{"template":"{{ [1,2] }} {{ 1/3 }}"}' | node maint/oracle.js`
- `docs/adr/` records every decided JS→Perl mapping and every deliberate difference. A
  difference without an ADR is a bug.
- Test suite: `prove -lr t/` (`-r` is mandatory). Author check: `prove -l xt/`.

The porting contract, the upstream-file → Perl-module map and the test layout live in
skill `text-nunjucks-core`; the measured JS-semantics catalogue in its
`references/js-semantics.md`.

## Delegation

Delegate behavior-relevant code to the right agent instead of touching it yourself —
the principle is a shared house rule (skilletor bundle `getty-cpan-dist@getty`); lanes
and hazards are in `.claude/rules/text-nunjucks-rules.md`.

| Task | Agent |
|---|---|
| Find out where something is, how upstream does it, what is missing (read-only) | `text-nunjucks-scout` |
| Port / implement / refactor / debug behavior-relevant code | `text-nunjucks-worker` (default) |
| Port upstream test suites, grow the corpus | `text-nunjucks-test-writer` |
| Audit a ported module against its upstream file (read-only) | `text-nunjucks-fidelity-auditor` |
| POD, README, the prose of a decided ADR | `text-nunjucks-doc-writer` |
| Commits, `Changes`, card → done, pre-release audit | `text-nunjucks-release-manager` |

Every subagent is a `text-nunjucks-*` agent, never the built-in `general-purpose`,
`Explore` or `Plan`: those get no briefing.

The agents carry their skills via `briefing.skills` (see `.claude/agents/`); the main
agent delegates rather than loading them. Skill sources live under `.claude/skills/` —
`text-nunjucks-core` is project-owned; the `getty-*`, `perl-release-dist-ini`,
`feedback-loop-debugging` and `kanban-issues-karr-*` ones are installed by skilletor from
`.claude/skilletor.json` and change in their source repos. `superpowers:*` skills come
from the superpowers plugin enabled in `.claude/settings.json`.

## Working the board

Work coordination runs on the local `karr` board; ids are written `kNN`. The order is
encoded in `depends_on` and follows the pipeline: filters (k17) → tests and globals (k18)
→ loaders (k19) → top-level API and POD (k20), each with its upstream test suite
(k33–k38). A card tagged `decision` needs the maintainer: put the options and a
recommendation in front of them, record the answer as an ADR.

Each porting ticket: test-writer ports the upstream suite (TODO) → worker ports →
fidelity-auditor compares against upstream → worker fixes findings → release-manager
commits → done.
