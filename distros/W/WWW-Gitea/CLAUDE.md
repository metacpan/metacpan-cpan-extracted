# CLAUDE.md — WWW::Gitea

Moo client for the Gitea REST API (api/v1). Modelled on `WWW::PayPal`: a `Role::HTTP`
transport, a `Role::OpenAPI` dispatch layer with pre-computed operation tables, thin
`API::*` controllers, and entity wrappers.

This distribution ships its own house rules (`.claude/rules/`), agents (`.claude/agents/`)
and skills (`.claude/skills/`). The build/test/POD/release machinery comes from the
`[@Author::GETTY]` plugin bundle — see the **perl-release-author-getty** and
**perl-release-dist-ini** skills. This file documents only what's specific to WWW::Gitea.

## House rules

Family-wide discipline, architecture and release rules live in
`.claude/rules/gitea-rules.md` — apply them to every task. The essentials:

- **Moo + namespace::clean.** No Moose. Transport only via `Role::HTTP`; dispatch only via
  `Role::OpenAPI` with pre-computed `operationId => {method, path}` tables. No runtime spec
  parsing.
- **Paths come from the Gitea swagger verbatim** (`https://gitea.com/swagger.v1.json`),
  including exact path-param names.
- **`our $VERSION` lives ONLY in `lib/WWW/Gitea.pm`.** Sibling modules carry no version line;
  `dist.ini` has `version_finder = :MainModule` and `MetaProvides::Package inherit_version=1`
  fills in the rest at build time.
- **`dzil release` only with explicit maintainer go-ahead.**

## Delegation

| Task | Agent |
|---|---|
| Implement / refactor / debug / test code | `gitea-worker` (default) |
| Write or improve POD | `pod-writer` |
| Add / extend tests | `perl-test-writer` |
| Pre-release audit (cpanfile pins, version placement, Changes, build) | `gitea-release-checker` |

Agents carry their skills via `briefing.skills` (the `briefing` plugin is enabled in
`.claude/settings.json`). Skill sources live under `.claude/skills/` — the shared ones
(`perl-core`, `perl-moo`, `perl-release-*`) are hardlinked in via `manage-skills`; the
project-specific consumer doc is `perl-www-gitea`.

## Structure

```
lib/WWW/Gitea.pm                     # Main client — url/token/basic auth, api_url, controllers
lib/WWW/Gitea/Role/HTTP.pm           # token/basic auth + JSON request + request_status
lib/WWW/Gitea/Role/OpenAPI.pm        # operationId dispatch over pre-computed tables
lib/WWW/Gitea/API/Misc.pm            # version, current_user
lib/WWW/Gitea/API/Users.pm           # get, search
lib/WWW/Gitea/API/Repos.pm           # get/create/edit/delete/search/fork/list
lib/WWW/Gitea/API/Issues.pm          # list/create/get/edit/search + comments
lib/WWW/Gitea/API/PullRequests.pm    # list/create/get/edit/merge/is_merged
lib/WWW/Gitea/API/Labels.pm          # list/create/get/edit/delete
lib/WWW/Gitea/API/Milestones.pm      # list/create/get/edit/delete
lib/WWW/Gitea/API/Releases.pm        # list/create/get/get_by_tag/edit/delete
lib/WWW/Gitea/API/Orgs.pm            # get/create/edit/delete/repos/list
lib/WWW/Gitea/{User,Repo,Issue,PullRequest,Label,Milestone,Release,Org,Comment}.pm  # entities
t/load.t                             # module load
t/openapi.t                          # operation tables, path substitution, auth, entity parsing
```

## Design notes

- **Auth** (`Role::HTTP`): a `token` → `Authorization: token <TOKEN>` (Gitea's scheme, not
  `Bearer`); otherwise `username` + `password` → HTTP Basic. `request` decodes JSON and
  croaks the Gitea error message on non-2xx; `request_status` returns the bare status code
  without croaking (used by `pulls->is_merged`, a 204/404 status-only endpoint).
- **`api_url`** is derived from `url` (instance root) + `/api/v1`; trailing slash / accidental
  `/api/v1` suffix are tolerated.
- **Entities** keep raw JSON on `->data` and a weak `client` ref. Repo-scoped entities take
  `owner`/`repo`; `Issue`/`PullRequest` fall back to the embedded `repository` / `base.repo`
  block so cross-repo `search` results still support lifecycle methods.

## Testing

`prove -l t/` — fully network-free (operation tables, path substitution, auth headers, entity
parsing from sample JSON). Never hit a real Gitea instance in `t/`. `dzil build` to verify
packaging + that `META.json` `provides` lists every package at the dist version.

## Related

- `perl-www-gitea` skill — consumer-facing usage (for AIs working on projects that import
  `WWW::Gitea`)
- `perl-core` / `perl-moo` skills — house Perl style and Moo patterns
- `perl-release-author-getty` / `perl-release-dist-ini` skills — build/POD/release workflow
- Gitea API: <https://docs.gitea.com/api/> · swagger: <https://gitea.com/swagger.v1.json>
