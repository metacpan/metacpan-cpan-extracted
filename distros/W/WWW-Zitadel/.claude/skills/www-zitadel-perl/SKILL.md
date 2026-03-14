---
name: www-zitadel-perl
description: "Usage guide for WWW::Zitadel Perl client (OIDC, Management API, token flows, tests)"
user-invocable: true
allowed-tools: Read, Grep, Glob, Bash
model: sonnet
---

Use this skill when the task is "how do I use `WWW::Zitadel` in Perl?".

## Module map

- `WWW::Zitadel`: unified entrypoint (`issuer`, optional `token`)
- `WWW::Zitadel::OIDC`: discovery, JWKS, token verification, userinfo, introspection, token endpoint helpers
- `WWW::Zitadel::Management`: Management API v1 (users/projects/apps/roles/grants/IDPs)
- `WWW::Zitadel::Error`: exception base; subclasses `::Validation`, `::Network`, `::API`

Async equivalent: `Net::Async::Zitadel` in `p5-net-async-zitadel/` — same API surface with `_f` suffixes returning Futures.

## Quickstart (unified entrypoint)

```perl
use WWW::Zitadel;

my $z = WWW::Zitadel->new(
  issuer => 'https://zitadel.example.com',
  token  => $ENV{ZITADEL_PAT}, # only needed for management calls
);

my $claims = $z->oidc->verify_token($jwt, audience => 'client-id');
my $projects = $z->management->list_projects(limit => 20);
```

Important: management methods are direct methods like
`list_users`, `create_human_user`, `create_project` (no `->users->list` subclient API).

## OIDC usage

Typical calls:

- `discovery`
- `jwks(force_refresh => 1?)`
- `verify_token($jwt, audience => ..., verify_exp => 1, ...)`
- `userinfo($access_token)`
- `introspect($token, client_id => ..., client_secret => ...)`
- `client_credentials_token(...)`
- `refresh_token($refresh_token, ...)`
- `exchange_authorization_code(code => ..., redirect_uri => ..., ...)`

`verify_token` retries once with refreshed JWKS when signature validation fails
(useful for key rotation).

## Management API usage

Create client:

```perl
my $mgmt = WWW::Zitadel::Management->new(
  base_url => 'https://zitadel.example.com',
  token    => $ENV{ZITADEL_PAT},
);
```

Common flow:

1. `create_project(name => ...)`
2. `create_oidc_app($project_id, name => ..., redirect_uris => [...])`
3. `add_project_role($project_id, role_key => ...)`
4. `create_user_grant(user_id => ..., project_id => ..., role_keys => [...])`

## Error handling

Errors throw typed exception objects (subclasses of `WWW::Zitadel::Error`).
They stringify to their message, so plain `eval`/`$@` string matching still works.

```perl
eval { $mgmt->get_user($id) };
if (my $err = $@) {
    if (ref $err && $err->isa('WWW::Zitadel::Error::API')) {
        warn "HTTP: ", $err->http_status, "\n";  # e.g. "404 Not Found"
        warn "Msg:  ", $err->api_message,  "\n";  # from Zitadel JSON body
    }
    die $err;  # re-throw
}
```

Exception classes:
- `WWW::Zitadel::Error::Validation` — bad args before any HTTP call
- `WWW::Zitadel::Error::Network`   — HTTP-level failure (non-2xx for OIDC endpoints)
- `WWW::Zitadel::Error::API`       — non-2xx from Management API (has `http_status`, `api_message`)

## Common gotchas for AI

**PAT creation**: ZITADEL UI → Users (top-right avatar) → Personal Access Tokens → Add.
Service accounts: Users → Service Users → create → Keys tab → add key.

**API base path**: Always appends `/management/v1` — don't double-include it in paths.

**Token format**: `Authorization: Bearer <PAT>` — always Bearer, never Basic.

**IDP configuration**: After `create_oidc_idp`, call `activate_idp($id)` — IDPs start inactive.
The `scopes` default is `["openid","profile","email"]`.

**User types**: `create_human_user` → human login users; `create_service_user` → machine/JWT users.
Service users can't log in interactively — use machine keys (`add_machine_key`).

**Metadata values**: Zitadel stores metadata base64-encoded. The client handles encoding on write
automatically. On read, `$meta->{metadata}{value}` comes back base64-encoded — decode it yourself
with `MIME::Base64::decode_base64($v)` if needed.

**LWP + self-signed TLS**: Add `ssl_opts => { verify_hostname => 0 }` to `LWP::UserAgent->new`
for dev instances with self-signed certs (not for production).

**CORS**: For browser-based OIDC, add allowed origins in ZITADEL under the app's settings.

**PostgreSQL 18 + self-hosted**: If init fails with "partitioned tables cannot be unlogged",
use ZITADEL v4.11.0+ which includes the PG18 compatibility fix.

## Test commands

Offline tests:

```bash
cd /storage/raid/home/getty/dev/perl/p5-www-zitadel
prove -lr t
```

Live issuer tests:

```bash
ZITADEL_LIVE_TEST=1 \
ZITADEL_ISSUER='https://your-zitadel.example.com' \
prove -lv t/90-live-zitadel.t
```

Kubernetes pod reachability test:

```bash
ZITADEL_K8S_TEST=1 \
ZITADEL_ISSUER='https://your-zitadel.example.com' \
ZITADEL_KUBECONFIG='/storage/raid/home/getty/avatar/.kube/config' \
prove -lv t/91-k8s-pod.t
```
