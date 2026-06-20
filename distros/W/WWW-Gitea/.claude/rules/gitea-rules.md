# WWW::Gitea House Rules

Apply to every task in this distribution unless explicitly overridden. Bias: caution over
speed on non-trivial work; use judgment on trivial tasks.

## Engineering discipline

1. **Think before coding** — State assumptions explicitly. When uncertain, ask rather than
   guess. Push back when a simpler approach exists. Stop when confused; name what's unclear.
2. **Simplicity first** — Minimum code that solves the problem. Nothing speculative. No
   abstractions for single-use code.
3. **Surgical changes** — Touch only what you must. Don't "improve" adjacent code or
   formatting. Match the existing style (this dist mirrors `WWW::PayPal`).
4. **Read before you write** — Before new code, read the role(s), an existing API controller
   and an existing entity. They are the template; conform to them.
5. **Fail loud** — "Done" is wrong if anything was skipped silently. "Tests pass" is wrong if
   any were skipped. Surface uncertainty, don't hide it.

## Architecture (non-negotiable — mirrors WWW::PayPal)

- **Moo + `namespace::clean`** everywhere. No Moose, no Moose deps.
- **`WWW::Gitea::Role::HTTP`** owns transport + auth (token / basic). Nothing else builds
  `HTTP::Request`s or talks to `LWP` directly.
- **`WWW::Gitea::Role::OpenAPI`** owns dispatch. Every API controller ships a pre-computed
  `openapi_operations` table (`operationId => { method, path }`) and calls `call_operation`.
  **No runtime OpenAPI/YAML parsing, ever.**
- **API controllers** (`WWW::Gitea::API::*`) take `client` (weak_ref), hold the operation
  table, and expose high-level methods that wrap `call_operation` and return entities.
- **Entities** (`WWW::Gitea::Repo`, `::Issue`, ...) wrap raw JSON: `has _client` (weak_ref,
  `init_arg => 'client'`), `has data` (rw, required), field accessors, and lifecycle methods
  that delegate back to the controllers. Keep `->data` available; only expose fields that
  have a real consumer.
- **Paths come from the spec.** When adding an operation, take method+path from the Gitea
  swagger (`https://gitea.com/swagger.v1.json`) verbatim — including the exact path-param
  names (`{owner}`, `{repo}`, `{index}`, `{id}`, `{tag}`, `{username}`, `{org}`). Watch the
  non-obvious ones: cross-repo issue search is `/repos/issues/search`; labels/milestones are
  addressed by `{id}` not name; `GET .../pulls/{index}/merge` is the status-only is-merged
  check (204/404).

## Versioning — version lives ONLY in the main module

`our $VERSION` belongs in `lib/WWW/Gitea.pm` and **nowhere else**. Sibling `.pm` files carry
no `$VERSION` line; the build injects the right version into `META` (`MetaProvides::Package
inherit_version=1`) and the dist.ini sets `version_finder = :MainModule` so only the main
module is rewritten/bumped. Do NOT add `our $VERSION` to new sibling modules.

## Changes

Add a bullet under `{{$NEXT}}` in `Changes` in the SAME change as any user-facing addition
(new controller, new method, behaviour change, bug fix). Two-space indent, `  - ` bullets,
present tense. Never hand-edit the version line — `[@Author::GETTY]` owns it.

## Release — never without permission

`dzil build` / `dzil test` are fine anytime. `dzil release` and any CPAN upload are STRICTLY
forbidden without the maintainer's explicit go-ahead — even if a plan lists "release" as the
next step. For anything heading toward release: stop and ask. Use the `gitea-release-checker`
agent for the pre-release audit.
