---
name: openbao-general
description: Load when implementing or reviewing a client that talks to OpenBao or Vault — KV v2 shapes, the soft-delete vs destroy ladder, LIST/SCAN, Kubernetes auth, sys/* endpoints.
---

# OpenBao / Vault HTTP API

OpenBao is the OpenSSF fork of HashiCorp Vault. The API surface below is verified against
**OpenBao 2.6.x** (`https://openbao.org/api-docs/`). Everything is `/v1/`-prefixed, all
bodies are JSON, and authentication is the `X-Vault-Token` request header.

**Vault compatibility.** Everything in this file works on both unless marked
`OpenBao-only`. Do not assume an OpenBao extension exists on Vault.

## Response envelope

Successful reads wrap payload in `data`; some endpoints nest a second `data` inside it:

```json
{ "data": { "data": { "user": "app" }, "metadata": { "version": 2, "destroyed": false } } }
```

Errors return a non-2xx status with `{"errors":["permission denied"]}`. Writes that
produce nothing return **204 with an empty body** — an empty body is success, not a
missing response. `404` is ambiguous: a genuinely absent path *and* a soft-deleted KV v2
version both answer 404.

## KV v2

Mount path is variable (`secret` by default). Two parallel trees per mount — `data/` for
values, `metadata/` for versions and key info — and confusing them is the single most
common bug in a KV v2 client.

| Operation | Method | Path |
|---|---|---|
| Read secret (latest, or `?version=N`) | `GET` | `/v1/:mount/data/:path` |
| Create/update (new version) | `POST` | `/v1/:mount/data/:path` |
| Partial update (merge patch) | `PATCH` | `/v1/:mount/data/:path` |
| Read subkeys, values stripped | `GET` | `/v1/:mount/subkeys/:path` |
| **Soft**-delete latest version | `DELETE` | `/v1/:mount/data/:path` |
| **Soft**-delete named versions | `POST` | `/v1/:mount/delete/:path` |
| Undelete named versions | `POST` | `/v1/:mount/undelete/:path` |
| **Destroy** named versions (irreversible) | `PUT` | `/v1/:mount/destroy/:path` |
| List keys | `LIST` | `/v1/:mount/metadata/:path` |
| List keys recursively (`OpenBao-only`) | `SCAN` | `/v1/:mount/metadata/:path` |
| List + full metadata (`OpenBao-only`) | `LIST`/`SCAN` | `/v1/:mount/detailed-metadata/:path` |
| Read metadata / version history | `GET` | `/v1/:mount/metadata/:path` |
| Create/update metadata (no new version) | `POST` | `/v1/:mount/metadata/:path` |
| **Delete key + every version** (irreversible) | `DELETE` | `/v1/:mount/metadata/:path` |
| Engine config | `GET`/`POST` | `/v1/:mount/config` |

### The delete ladder — three levels, not one

1. `DELETE .../data/:path` — soft. Version marked deleted, reads 404, data still stored,
   reversible via `undelete`.
2. `PUT .../destroy/:path` — the *version's* bytes are gone; key and metadata survive.
3. `DELETE .../metadata/:path` — key, all versions, all history gone.

A method named "delete" that hits `metadata/` is the destructive one. Document which
level a client method implements; callers routinely assume level 1 and get level 3.

### Write body

```json
{ "options": { "cas": 3 }, "data": { "user": "app" } }
```

`data` is required and replaces the whole map (`PATCH` merges instead). `cas` is optional
unless `cas_required` is set on the mount or key; it must equal the current version, or
`0` to assert "must not exist". `PATCH` requires `Content-Type: application/merge-patch+json`
and a `cas` greater than 0.

### Read response

`data.data` is the secret map; `data.metadata` carries `version`, `created_time`,
`deletion_time`, `destroyed`, `custom_metadata`. A client returning only `data.data`
discards the version — fine as a default, but then version-aware callers need a second
entry point rather than a flag bolted onto the same return value.

### List response

`{"data":{"keys":["foo","foo/"]}}` — a trailing `/` means "folder", i.e. there are keys
*below* `foo`, which may or may not coexist with a secret *at* `foo`. Listing a leaf
returns nothing, not an empty list. Keys are **not** policy-filtered, so never encode
secrets in key names. Paginate with `after=` / `limit=`.

`LIST` as an HTTP verb dies in some proxies and clients; `GET .../metadata/:path?list=true`
is the equivalent fallback and is worth supporting where a custom verb is a liability.

## Kubernetes auth

```
POST /v1/auth/kubernetes/login    { "role": "...", "jwt": "..." }
```

Unauthenticated — no `X-Vault-Token` needed. The in-pod ServiceAccount JWT lives at
`/var/run/secrets/kubernetes.io/serviceaccount/token`; the CA at `…/ca.crt` in the same
directory. Response:

```json
{ "auth": { "client_token": "…", "accessor": "…", "policies": ["default"],
            "metadata": { "role": "…", "service_account_name": "…" },
            "lease_duration": 2764800, "renewable": true } }
```

`lease_duration` is seconds and `renewable` is usually true — a long-lived process that
ignores both will hit an expired token and see 403, not 401. Renewal is
`POST /v1/auth/token/renew-self`.

The mount path is configurable; `auth/kubernetes` is only the default. A client hardcoding
it cannot talk to a cluster that mounted the method elsewhere.

## sys/* endpoints

| Operation | Method | Path | Notes |
|---|---|---|---|
| Health | `GET`/`HEAD` | `/v1/sys/health` | **status code carries the answer** |
| Init status | `GET` | `/v1/sys/init` | `{"initialized":bool}` |
| Initialize | `POST` | `/v1/sys/init` | returns `keys`, `keys_base64`, `root_token` |
| Unseal | `POST` | `/v1/sys/unseal` | one key share per call |
| Seal status | `GET` | `/v1/sys/seal-status` | |
| Mount an engine | `POST` | `/v1/sys/mounts/:path` | `{"type":"kv-v2"}`, answers 204 |
| List mounts | `GET` | `/v1/sys/mounts` | |

### Health status codes are the API

- `200` initialized, unsealed, active
- `429` unsealed but **standby**
- `501` **not initialized**
- `503` **sealed**

Only 200 is a 2xx. Any client that treats non-2xx as failure collapses "sealed",
"standby", "uninitialised" and "host unreachable" into one indistinguishable error —
which is exactly the state an operator is trying to tell apart. Read the status code, or
pass `standbyok=true` / `sealedcode=200` / `uninitcode=200` to flatten the codes
deliberately.

### init returns the only copy of the keys

`POST /sys/init` hands back the unseal key shares and the initial root token **once**.
They are unrecoverable. Never log the response, never write it anywhere unintended, and
treat any code path that discards it as a bug. `secret_shares`/`secret_threshold` are
required; `threshold <= shares`.

## Security notes for clients

- The token is a bearer credential. Never put it in a URL, a log line, or an exception
  message — error text that echoes the request body will leak secret values too.
- 403 (`permission denied`) and 404 (`not found`) are different answers. A helper that
  turns "can't read it" into "doesn't exist" tells the caller a comfortable lie; ACLs
  deliberately answer 403 on paths that do exist.
- TLS verification off is a development shortcut, never a default.
