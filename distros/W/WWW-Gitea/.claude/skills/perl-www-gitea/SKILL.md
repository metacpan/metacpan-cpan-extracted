---
name: perl-www-gitea
description: "WWW::Gitea — Perl (Moo) client for the Gitea REST API (api/v1). Repos, issues, pull requests, labels, milestones, releases, organizations and users via token or basic auth."
user-invocable: false
allowed-tools: Read, Grep, Glob
model: sonnet
---

# WWW::Gitea

Perl client for the Gitea REST API. Use when the project imports `WWW::Gitea`, calls
`$gitea->repos` / `$gitea->issues` / `$gitea->pulls` / `$gitea->orgs`, or talks to a
self-hosted Gitea (or Forgejo, which is API-compatible) instance.

## Client setup

```perl
use WWW::Gitea;

my $gitea = WWW::Gitea->new(
    url   => 'https://gitea.example.com',   # instance ROOT, no /api/v1 (required)
    token => $ENV{GITEA_TOKEN},             # personal access token
);
```

- `url` is the instance root — `/api/v1` is appended for you (a trailing slash or an
  accidental `/api/v1` suffix is tolerated). Defaults to `$ENV{GITEA_URL}`.
- Auth: a `token` is sent as `Authorization: token <TOKEN>` (Gitea's scheme — note the
  literal word `token`, not `Bearer`). Without a token, `username` + `password` fall back to
  HTTP Basic. Defaults: `GITEA_TOKEN`, `GITEA_USERNAME`, `GITEA_PASSWORD`.
- Self-hosted ⇒ there is no built-in base URL and no sandbox flag (unlike `WWW::PayPal`).

Create a token in Gitea under *Settings → Applications → Generate New Token* with the scopes
you need (e.g. `repo`, `issue`, `organization`).

## Resource controllers

Everything hangs off the client. Controllers are lazy and cached:

| Accessor             | Class                            | Covers                                  |
|----------------------|----------------------------------|-----------------------------------------|
| `$gitea->misc`       | `API::Misc`                      | `version`, `current_user`               |
| `$gitea->users`      | `API::Users`                     | get, search                             |
| `$gitea->repos`      | `API::Repos`                     | get/create/edit/delete/search/fork/list |
| `$gitea->issues`     | `API::Issues`                    | list/create/get/edit/search + comments  |
| `$gitea->pulls`      | `API::PullRequests`              | list/create/get/edit/merge/is_merged    |
| `$gitea->labels`     | `API::Labels`                    | list/create/get/edit/delete             |
| `$gitea->milestones` | `API::Milestones`                | list/create/get/edit/delete             |
| `$gitea->releases`   | `API::Releases`                  | list/create/get/get_by_tag/edit/delete  |
| `$gitea->orgs`       | `API::Orgs`                      | get/create/edit/delete/repos/list       |

`owner`/`repo`/`index`/`id` are passed as positional arguments; the request body / query
params are named arguments.

## Common flows

### Identify + repositories

```perl
my $me  = $gitea->current_user;          # WWW::Gitea::User  (shortcut for misc->current_user)
my $ver = $gitea->version;               # "1.22.0"          (shortcut for misc->version)

my $repo = $gitea->repos->get('getty', 'p5-www-gitea');
$repo->full_name;     # "getty/p5-www-gitea"
$repo->clone_url;
$repo->stars_count;

# Create under the authenticated user, or under an org with org => '...'
my $new = $gitea->repos->create(
    name => 'my-repo', description => '...', private => 1, auto_init => 1,
);
my $org_repo = $gitea->repos->create(org => 'myorg', name => 'svc');

my $hits = $gitea->repos->search(q => 'gitea', limit => 10);   # ArrayRef of Repo
my $mine = $gitea->repos->list;                                # authed user's repos
```

### Issues + comments

```perl
my $issues = $gitea->issues->list('getty', 'p5-www-gitea', state => 'open', labels => 'bug');

my $issue = $gitea->issues->create('getty', 'p5-www-gitea',
    title => 'Bug', body => '...', labels => [1, 2], assignees => ['getty']);

$issue->number;            # per-repo index shown in the UI
$issue->state;             # open / closed
$issue->label_names;       # ['bug', ...]
$issue->add_comment('looking into it');
$issue->close;             # == $issue->edit(state => 'closed')

# cross-repo search
my $found = $gitea->issues->search(q => 'crash', state => 'open', type => 'issues');
```

### Pull requests

```perl
my $pr = $gitea->pulls->create('getty', 'p5-www-gitea',
    head => 'feature', base => 'main', title => 'Add feature');
#   head may be 'user:branch' for a cross-fork PR

$pr->head_branch;  $pr->base_branch;
$gitea->pulls->merge('getty', 'p5-www-gitea', $pr->number, Do => 'squash');
#   Do: merge | rebase | rebase-merge | squash | manually-merged   (default: merge)

my $merged = $gitea->pulls->is_merged('getty', 'p5-www-gitea', $pr->number);  # bool
#   GET .../pulls/{index}/merge → 204 merged / 404 not merged (status only)
```

### Labels / milestones / releases

```perl
my $label = $gitea->labels->create('getty', 'repo', name => 'bug', color => 'ee0701');
my $ms    = $gitea->milestones->create('getty', 'repo', title => 'v1.0');
my $rel   = $gitea->releases->create('getty', 'repo',
    tag_name => 'v1.0.0', name => 'First release', body => 'Changelog');
my $byTag = $gitea->releases->get_by_tag('getty', 'repo', 'v1.0.0');
```

Labels, milestones and releases are addressed by numeric **`id`** (not name) — except a
release also has `get_by_tag`.

### Organizations

```perl
my $org   = $gitea->orgs->get('perl-modules');
my $repos = $gitea->orgs->repos('perl-modules');   # ArrayRef of Repo
my $mine  = $gitea->orgs->list;                    # orgs the authed user belongs to
```

## Entity objects

Every call returns a small entity (`WWW::Gitea::Repo`, `::Issue`, `::PullRequest`, `::Label`,
`::Milestone`, `::Release`, `::Org`, `::User`, `::Comment`). They expose the commonly needed
fields as accessors and keep the full decoded JSON on `->data`:

```perl
$issue->data->{pull_request};            # reach anything not exposed as an accessor
$repo->data->{permissions}{admin};
```

If you find yourself reaching into `->data` for the same field repeatedly, add an accessor to
the entity class rather than duplicating the path.

Repo-scoped entities (`Issue`, `PullRequest`, `Label`, `Milestone`, `Release`) carry their
`owner`/`repo` so lifecycle methods work directly:

```perl
$issue->edit(title => '...'); $issue->reopen; $issue->refresh;
$pr->merge(Do => 'rebase');   $pr->close;
$ms->close;                   $label->edit(color => '00ff00');   $rel->delete;
```

For `Issue`/`PullRequest` the owner/repo also fall back to the embedded `repository` /
`base.repo` block in the JSON, so entities returned by cross-repo `search` still work.

`WWW::Gitea::Repo` additionally delegates: `$repo->issues`, `$repo->create_issue(...)`,
`$repo->pulls`, `$repo->labels`, `$repo->milestones`, `$repo->releases`.

## Gotchas

- **Auth scheme is `token`, not `Bearer`.** `Authorization: token <TOKEN>`.
- **`url` is the instance root**, not the API endpoint. Pass `https://gitea.example.com`, not
  `https://gitea.example.com/api/v1` (though the latter is tolerated).
- **Issues and PRs share the number space** and are both addressed by `index`. The issues
  list can return PRs too — filter with `type => 'issues'` / `type => 'pulls'`.
- **Cross-repo issue search is `/repos/issues/search`**, not `/issues/search`.
- **Labels/milestones/releases use numeric `id`**, not name (releases also have `get_by_tag`).
- **Errors croak.** Non-2xx responses throw `Gitea API error (METHOD path): <message>`; wrap
  calls in `eval` / `Try::Tiny` if you need to handle e.g. 404s. The one exception is
  `pulls->is_merged`, which returns a bool from the status code instead of croaking on 404.
- **Booleans:** Gitea wants JSON booleans in bodies — pass `\1` / `\0` (or `JSON::MaybeXS`'s
  `true`/`false`) for fields like `draft`, `private`, `archived`.
- **Forgejo** (the Gitea fork) exposes the same `api/v1` surface — this client works against
  it unchanged.

## Adding a new resource

1. Controller `lib/WWW/Gitea/API/Foo.pm`: `has client` (weak_ref), `has openapi_operations`
   (operationId → `{method, path}` taken verbatim from the Gitea swagger), `with
   'WWW::Gitea::Role::OpenAPI'`, high-level methods wrapping `call_operation`, a `_wrap`
   helper returning the entity.
2. Entity `lib/WWW/Gitea/Foo.pm`: `has _client` (weak_ref, `init_arg => 'client'`), `has
   data` (rw, required), field accessors, lifecycle methods delegating back to the controller.
3. Wire the controller into `lib/WWW/Gitea.pm` as a `lazy` attribute (+ `use`).
4. Add the modules to `t/load.t`; cover operation lookup + entity parsing in `t/openapi.t`.
5. `our $VERSION` stays only in `lib/WWW/Gitea.pm` — do not add it to the new files.
