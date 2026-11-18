# ADR 0022 — Upstream files that are out of scope

- Status: accepted
- Date: 2026-11-17
- Tags: scope, k24, k23

## Context

Upstream ships files that do not belong to the template pipeline. The scope
list in skill `text-nunjucks-core` (`.claude/skills/text-nunjucks-core/SKILL.md`)
has named them since the bootstrap commit 762c0c9 (2026-09-22), but no ADR
recorded it. The k24 release audit found that gap: a difference without an ADR
is a bug.

## Decision

The scope list stands as the core skill has stated it, "by decision", since the
bootstrap: `express-app.js`, `web-loaders.js`, `precompile-global.js`, the browser
bundles, `NodeResolveLoader` and `FileSystemLoader`'s chokidar `watch` are out of
scope. They are not ported and leave no stubs. The skill gives no reasons; the
descriptions below are factual, written for this ADR.

- **`express-app.js`** is the module behind upstream's `Environment#express(app)`
  (`environment.js:292`), which wires Nunjucks into an Express application, and
  of the `express` option of `nunjucks.configure({ express: app })`
  (`index.js:40`). `Text::Nunjucks::Environment` has no `express` method. Express is a node web
  framework; Perl has no analogue in this distribution.
- **The browser bundles** are the builds for use in a browser. The port runs on
  Perl only.
- **`web-loaders.js` (`WebLoader`), `NodeResolveLoader` and chokidar `watch`**
  are covered by ADR 0018, including what a truthy `watch` does.
- **`precompile-global.js`** is the wrapper `precompile.js` uses by default to
  emit JavaScript source for a precompiled template. It is out of scope.

## Consequences

- `Text::Nunjucks` lists these under STATUS and "DIFFERENCES FROM NUNJUCKS"
  (Scope and platform).
- **Open conflict with k23 (tag `decision`).** `precompile.js` requires
  `precompile-global.js` and uses `precompileGlobal` as its default wrapper
  (`precompile.js:8, 21, 46`), so a port of `precompile` cannot keep this file out
  of scope unchanged. Whether `precompile` is ported at all, and in which format,
  is k23's decision for the maintainer. This ADR does not decide it. If k23
  ports `precompile`, this ADR and the scope list need an update.
- Reversible only by a maintainer decision to bring one of these into scope.
