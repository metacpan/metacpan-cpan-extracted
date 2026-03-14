# WWW-Zitadel

[![CPAN Version](https://img.shields.io/cpan/v/WWW-Zitadel.svg)](https://metacpan.org/pod/WWW::Zitadel)
[![License](https://img.shields.io/cpan/l/WWW-Zitadel.svg)](https://metacpan.org/pod/WWW::Zitadel)

Perl client for [ZITADEL](https://zitadel.com/) with two focused clients:

- `WWW::Zitadel::OIDC` for OpenID Connect discovery, JWKS, token verification,
  userinfo, and token introspection.
- `WWW::Zitadel::Management` for ZITADEL Management API v1 (users, projects,
  apps, roles, grants).

## Installation

```bash
cpanm WWW::Zitadel
```

For local development:

```bash
cpanm --installdeps .
prove -lr t
```

## Quickstart

### Unified entrypoint (`WWW::Zitadel`)

```perl
use WWW::Zitadel;

my $zitadel = WWW::Zitadel->new(
    issuer => 'https://zitadel.example.com',
    token  => $ENV{ZITADEL_PAT},
);

# OIDC access
my $claims = $zitadel->oidc->verify_token($jwt, audience => 'my-client-id');

# Management API access
my $projects = $zitadel->management->list_projects(limit => 20);
```

### OIDC client

```perl
use WWW::Zitadel::OIDC;

my $oidc = WWW::Zitadel::OIDC->new(
    issuer => 'https://zitadel.example.com',
);

# Read discovery metadata
my $discovery = $oidc->discovery;

# Verify JWT using issuer JWKS (with auto-refresh retry on key rotation)
my $claims = $oidc->verify_token(
    $jwt,
    audience => 'my-client-id',
);

# UserInfo endpoint
my $profile = $oidc->userinfo($access_token);

# Introspection endpoint (client credentials required)
my $introspection = $oidc->introspect(
    $access_token,
    client_id     => $client_id,
    client_secret => $client_secret,
);

# Client credentials grant
my $cc = $oidc->client_credentials_token(
    client_id     => $client_id,
    client_secret => $client_secret,
    scope         => 'openid profile',
);

# Refresh token grant
my $refreshed = $oidc->refresh_token(
    $refresh_token,
    client_id     => $client_id,
    client_secret => $client_secret,
);
```

### Management API client

```perl
use WWW::Zitadel::Management;

my $mgmt = WWW::Zitadel::Management->new(
    base_url => 'https://zitadel.example.com',
    token    => $ENV{ZITADEL_PAT},
);

# Human users
my $users = $mgmt->list_users(limit => 50);
my $user = $mgmt->create_human_user(
    user_name  => 'alice',
    first_name => 'Alice',
    last_name  => 'Smith',
    email      => 'alice@example.com',
);
$mgmt->set_password($user->{userId}, password => 'ch@ngeMe!');
$mgmt->set_user_metadata($user->{userId}, 'department', 'engineering');

# Service (machine) users + machine keys for JWT auth
my $svc = $mgmt->create_service_user(
    user_name => 'ci-bot',
    name      => 'CI Bot',
);
my $key = $mgmt->add_machine_key($svc->{userId});

# Projects
my $project = $mgmt->create_project(name => 'My Project');

# OIDC app inside a project
my $app = $mgmt->create_oidc_app(
    $project->{id},
    name          => 'web-client',
    redirect_uris => ['https://app.example.com/callback'],
);

# Update an OIDC app (all keys in snake_case, same as create)
$mgmt->update_oidc_app($project->{id}, $app->{appId},
    redirect_uris => ['https://app.example.com/callback', 'https://app.example.com/silent'],
    dev_mode      => JSON::MaybeXS::false,
);

# Roles and grants
$mgmt->add_project_role(
    $project->{id},
    role_key     => 'admin',
    display_name => 'Administrator',
);
$mgmt->create_user_grant(
    user_id    => $user->{userId},
    project_id => $project->{id},
    role_keys  => ['admin'],
);

# Organizations
my $orgs = $mgmt->list_orgs;
$mgmt->update_org(name => 'Acme Corp');

# Identity Providers (social login / federated IdPs)
my $idp = $mgmt->create_oidc_idp(
    name          => 'Google',
    client_id     => $google_client_id,
    client_secret => $google_client_secret,
    issuer        => 'https://accounts.google.com',
);
$mgmt->activate_idp($idp->{idp}{id});
```

### Sharing a single `LWP::UserAgent` (connection pooling)

Passing a shared UA instance to both clients lets them reuse the same
HTTP keep-alive connections to the ZITADEL server:

```perl
use LWP::UserAgent;
use WWW::Zitadel::OIDC;
use WWW::Zitadel::Management;

my $ua = LWP::UserAgent->new(timeout => 30);

my $oidc = WWW::Zitadel::OIDC->new(
    issuer => 'https://zitadel.example.com',
    ua     => $ua,
);
my $mgmt = WWW::Zitadel::Management->new(
    base_url => 'https://zitadel.example.com',
    token    => $ENV{ZITADEL_PAT},
    ua       => $ua,
);
```

Or use the `WWW::Zitadel` façade, which automatically shares one UA when
you access both `->oidc` and `->management`.

### Filtering with the `queries` parameter

All `list_*` methods accept a `queries` arrayref using ZITADEL's native
query filter format.  Each element is a query object as documented in the
[ZITADEL Management API reference](https://zitadel.com/docs/apis/mgmtapi).

```perl
# Find users whose display name contains "alice"
my $result = $mgmt->list_users(
    queries => [
        {
            displayNameQuery => {
                displayName => 'alice',
                method      => 'TEXT_QUERY_METHOD_CONTAINS',
            },
        },
    ],
);

# Find projects by name prefix
my $projects = $mgmt->list_projects(
    queries => [
        { nameQuery => { name => 'My', method => 'TEXT_QUERY_METHOD_STARTS_WITH' } },
    ],
);
```

### Token refresh strategy

ZITADEL access tokens are short-lived (default 12h). Common patterns:

- **On-demand**: call `$oidc->client_credentials_token(...)` before each
  operation, or cache the token until `exp - 60s`.
- **Proactive refresh**: track the `expires_in` from the token response and
  schedule a refresh at 80 % of the lifetime.
- **Lazy retry**: catch `WWW::Zitadel::Error::API` with `http_status`
  matching `401` and re-fetch a token before retrying once.

### JWKS key rotation

`verify_token` automatically retries with a fresh JWKS fetch when
signature verification fails (transparent key rotation handling).  The
JWKS is cached in the `WWW::Zitadel::OIDC` object for the lifetime of
the instance.  Force an immediate refresh:

```perl
$oidc->jwks(force_refresh => 1);
```

If you run multiple processes, each process maintains its own JWKS cache.
Under normal ZITADEL key rotation schedules (months) this is not an issue.
Set the object lifetime to match your deployment's rotation period if you
need tighter guarantees.

## Authentication

- OIDC methods use normal OIDC flows; no Management PAT is needed.
- Management API methods require a ZITADEL Personal Access Token (PAT).
- The token is sent as `Authorization: Bearer <token>`.

## Error handling

All errors are thrown as `WWW::Zitadel::Error` subclass objects.
Because they overload `""`, existing `eval`/`$@` string-matching patterns
continue to work.  For typed dispatch use `isa`:

```perl
use WWW::Zitadel::Error;

eval { $mgmt->get_user($user_id) };
if (my $err = $@) {
    if (ref $err && $err->isa('WWW::Zitadel::Error::API')) {
        # $err->http_status — e.g. "404 Not Found"
        # $err->api_message — message field from the JSON body
        warn "API error: $err";
    }
    elsif (ref $err && $err->isa('WWW::Zitadel::Error::Validation')) {
        warn "Bad argument: $err";
    }
    elsif (ref $err && $err->isa('WWW::Zitadel::Error::Network')) {
        warn "Network/HTTP error: $err";
    }
    else {
        die $err;  # re-throw unknown
    }
}
```

Three exception types:

| Class | When raised |
|---|---|
| `WWW::Zitadel::Error::Validation` | Missing/invalid arguments, empty issuer/base_url |
| `WWW::Zitadel::Error::Network` | Discovery, JWKS, UserInfo, Token endpoint HTTP failures |
| `WWW::Zitadel::Error::API` | Management API non-2xx responses |

## Development workflow

Typical local workflow:

```bash
cd /storage/raid/home/getty/dev/perl/p5-www-zitadel
cpanm --installdeps .
prove -lr t
```

Before release, also run opt-in live tests against a real issuer:

```bash
ZITADEL_LIVE_TEST=1 \
ZITADEL_ISSUER='https://your-zitadel.example.com' \
prove -lv t/90-live-zitadel.t
```

## Claude skill

Project-local ZITADEL skills:

- `.claude/skills/zitadel-general/SKILL.md` (integration + maintenance workflow)
- `.claude/skills/www-zitadel-perl/SKILL.md` (usage guide for Perl client)

## Testing

The test suite is fully offline and covers:

- constructor/validation behavior
- OIDC discovery, JWKS caching, and refresh-retry token verification
- OIDC token endpoint helpers (`client_credentials`, `refresh_token`, `authorization_code`)
- Management request composition (headers/body/path) and error propagation

Run all tests:

```bash
prove -lr t
```

### Live tests against a real ZITADEL instance

Enable optional live tests with environment variables:

```bash
export ZITADEL_LIVE_TEST=1
export ZITADEL_ISSUER='https://your-zitadel.example.com'

# Optional extras:
export ZITADEL_PAT='...'
export ZITADEL_ACCESS_TOKEN='...'
export ZITADEL_CLIENT_ID='...'
export ZITADEL_CLIENT_SECRET='...'
export ZITADEL_INTROSPECT_TOKEN='...'

prove -lv t/90-live-zitadel.t
```

### Kubernetes pod test (real cluster + real ZITADEL endpoint)

This test creates a temporary pod and validates that the pod can reach the
ZITADEL discovery endpoint:

```bash
export ZITADEL_K8S_TEST=1
export ZITADEL_ISSUER='https://your-zitadel.example.com'

# Optional:
export ZITADEL_KUBECONFIG='/storage/raid/home/getty/avatar/.kube/config'
export ZITADEL_K8S_NAMESPACE='default'
export ZITADEL_K8S_CONTEXT='your-context'

prove -lv t/91-k8s-pod.t
```

### End-to-end deployment on your cluster (Gateway API + cert-manager)

This repo includes a full deployment helper for your cluster setup:

```bash
cd /storage/raid/home/getty/dev/perl/p5-www-zitadel
script/deploy-k8s-zitadel.sh
```

Included assets:

- `k8s/zitadel/postgres.yaml` (simple `src.ci/srv/postgres:18` stack)
- `k8s/zitadel/postgres-values.yaml` (legacy bitnami reference)
- `k8s/zitadel/zitadel-values.yaml` (ZITADEL chart values)
- `k8s/zitadel/gateway-cert.yaml` (certificate for `*.avatar.conflict.industries`)
- `k8s/zitadel/httproute.yaml` (Gateway API route for ZITADEL + Login UI)

Useful overrides:

```bash
KUBECONFIG_PATH=/storage/raid/home/getty/avatar/.kube/config \
DOMAIN=zitadel.avatar.conflict.industries \
NAMESPACE=zitadel \
ZITADEL_IMAGE_REPOSITORY=src.ci/srv/zitadel \
ZITADEL_IMAGE_TAG=pg18-fix \
script/deploy-k8s-zitadel.sh
```

Important for PostgreSQL 18:

- Minimum recommended ZITADEL for PG18 is `v4.11.0` (or newer).
- ZITADEL `v4.10.1` contains migration `34_add_cache_schema` with SQL that fails on PG18:
  `partitioned tables cannot be unlogged (SQLSTATE 0A000)`.
- The fix is in PR `#11484` (`fix(setup): ensure PostgreSQL 18 compatibility`),
  released in `v4.11.0` (`ba1e9c2`, cherry-picked from `7a41fe96`).
- Reproduced against `src.ci/srv/postgres:18` (`PostgreSQL 18.3`): this is a
  ZITADEL migration issue, not a problem with the Postgres image itself.

You can run both live suites together:

```bash
ZITADEL_LIVE_TEST=1 ZITADEL_K8S_TEST=1 \
ZITADEL_ISSUER='https://your-zitadel.example.com' \
prove -lv t/90-live-zitadel.t t/91-k8s-pod.t
```

## Examples

Ready-to-run examples are in `examples/`:

- `examples/verify_token.pl` - verify an access token via OIDC + JWKS
- `examples/bootstrap_project.pl` - create a project, OIDC app, and role via Management API

Example usage:

```bash
ZITADEL_ISSUER='https://your-zitadel.example.com' \
ZITADEL_ACCESS_TOKEN='...' \
examples/verify_token.pl

ZITADEL_ISSUER='https://your-zitadel.example.com' \
ZITADEL_PAT='...' \
examples/bootstrap_project.pl
```

## API Overview

### `WWW::Zitadel::OIDC`

- `discovery`
- `jwks(force_refresh => 1?)`
- `verify_token($token, %opts)`
- `userinfo($access_token)`
- `introspect($token, client_id => ..., client_secret => ..., %opts)`
- `token(grant_type => ..., %form)`
- `client_credentials_token(client_id => ..., client_secret => ..., %form)`
- `refresh_token($refresh_token, %form)`
- `exchange_authorization_code(code => ..., redirect_uri => ..., %form)`

### `WWW::Zitadel::Management`

- Users: `list_users`, `get_user`, `create_human_user`, `update_user`,
  `deactivate_user`, `reactivate_user`, `delete_user`
- Passwords: `set_password`, `request_password_reset`
- Metadata: `set_user_metadata`, `get_user_metadata`, `list_user_metadata`
- Service users: `create_service_user`, `list_service_users`,
  `get_service_user`, `delete_service_user`
- Machine keys: `add_machine_key`, `list_machine_keys`, `remove_machine_key`
- Projects: `list_projects`, `get_project`, `create_project`,
  `update_project`, `delete_project`
- Apps: `list_apps`, `get_app`, `create_oidc_app`, `update_oidc_app`,
  `delete_app`
- Orgs: `get_org`, `create_org`, `list_orgs`, `update_org`, `deactivate_org`
- Roles: `add_project_role`, `list_project_roles`
- Grants: `create_user_grant`, `list_user_grants`
- IDPs: `create_oidc_idp`, `list_idps`, `get_idp`, `update_idp`,
  `delete_idp`, `activate_idp`, `deactivate_idp`

### `WWW::Zitadel::Error`

- `WWW::Zitadel::Error` (base, stringifies to `message`)
- `WWW::Zitadel::Error::Validation`
- `WWW::Zitadel::Error::Network`
- `WWW::Zitadel::Error::API` (adds `http_status`, `api_message`)

## See also

- `WWW::Zitadel`
- `WWW::Zitadel::OIDC`
- `WWW::Zitadel::Management`
