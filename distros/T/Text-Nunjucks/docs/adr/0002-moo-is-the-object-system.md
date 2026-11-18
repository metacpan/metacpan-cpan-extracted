# ADR 0002 — Moo is the object system; upstream's object.js is not ported

- Status: accepted
- Date: 2026-09-22
- Tags: structure, dependencies

## Context

Upstream builds its classes on `src/object.js` (`Obj.extend`, `EmitterObj`). The
alternative for a template engine — zero dependencies, plain `bless` — was on
the table for start-up time.

## Decision

Moo, the house standard, for every class. `object.js` has no Perl counterpart:
`extend` becomes `extends`/subclassing, `EmitterObj` becomes a small role with
`on`/`emit`. The ~60 AST node types are **generated** from their field lists in
`Text::Nunjucks::Nodes`, mirroring `Node.extend(name, { fields })` — not sixty
hand-written class files, and not a second object system. *Superseded by
ADR 0020 (k116, 2026-11-17) in this one point: every node type is now a
hand-written class in its own file. Moo for every class stands.*

## Consequences

- User extension points that upstream offers through `Loader.extend({...})` and
  `Environment` subclassing are offered through ordinary Perl subclassing.
- Node construction is on the parser's hot path; if Moo construction shows up in
  the benchmark (ticket k25), optimise the generated constructor, do not switch
  object systems.
