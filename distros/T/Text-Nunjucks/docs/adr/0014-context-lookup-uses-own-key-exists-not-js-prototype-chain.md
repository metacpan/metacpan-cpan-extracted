# ADR 0014 — Context.lookup uses Perl own-key exists, not the JS `in` prototype chain

- Status: accepted
- Date: 2026-09-22
- Tags: semantics, environment, decision, k16

## Context

`Context.lookup` decides whether a name resolves from the globals bag or the
context. Upstream (environment.js:356) writes:

```js
if (name in this.env.globals && !(name in this.ctx)) { ... }
```

JavaScript's `in` walks the whole prototype chain. Every plain JS object
inherits `Object.prototype`, so `'toString' in {}` is `true` and the value is the
inherited native function. Perl's `exists` (and the runtime's
`contextOrFrameLookup` → `context.lookup`, runtime.js:252 / `Runtime.pm:583`)
sees own keys only.

Oracle-confirmed divergence for an *unset* variable whose name collides with an
`Object.prototype` member:

| Template (name never set in context) | Upstream | Port (own-key exists) |
|---|---|---|
| `{{ toString }}` | `function toString() { [native code] }` | empty |
| `{{ constructor }}` | `function Object() { [native code] }` | empty |
| `{{ hasOwnProperty }}` / `{{ valueOf }}` | native function | empty |
| `{{ toString is defined }}` / `if toString` | `true` / truthy | `false` / falsy |

## Decision

`Context.lookup` uses own-key `exists`. The port does **not** emulate the JS
prototype chain, and does **not** synthesise `[native code]` function strings for
`Object.prototype` member names. A template variable resolves only if it was
actually set — as a global or as an own key of the context.

This is a deliberate divergence from the oracle, recorded here rather than left
silent. It is reachable only when a template reads a variable it never set whose
*name* happens to be an `Object.prototype` member (`toString`, `constructor`,
`hasOwnProperty`, `valueOf`, `isPrototypeOf`, `propertyIsEnumerable`,
`toLocaleString`) — a pathological collision, never normal data.

## Consequences

- `{{ toString }}` and its siblings render empty and read as undefined; upstream
  yields the inherited native function. Any template relying on that JS quirk is
  not portable, by design.
- These templates are deliberately **kept out of the corpus**: pinning the
  oracle's `[native code]` output as `expected` would make `xt/oracle-live.t`
  and the render corpus permanently red against a behaviour we have chosen not to
  reproduce. The divergence lives in this ADR, not in a red test.
- Reproducing upstream would require a curated map of prototype names to
  frozen native-code strings — high effort, fragile against any name not in the
  map, and of no value to real templates. Rejected.
