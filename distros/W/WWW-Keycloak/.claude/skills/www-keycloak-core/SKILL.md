---
name: www-keycloak-core
description: Use when working on WWW::Keycloak — the synchronous Perl client for Keycloak's OIDC endpoints and Admin REST API, its module layout, error classes, or its tests.
---

# WWW::Keycloak core

Synchronous Perl client for Keycloak, modelled on `WWW::Zitadel` (`~/dev/p5-www-zitadel`).
Phase 1 is built (2026-10-03). Section 12 of the design lists what the real Keycloak
forced on the implementation; read it before changing any `ensure_*` method.

**The design is `docs/superpowers/specs/2026-10-02-www-keycloak-design.md`** (draft, awaiting
review). It carries the API surface, the `ensure_*` rules and a table of Admin REST calls
observed against Keycloak 26.8.0. Read the section you work in; the spec wins over this
skill.

## Module map

- `WWW::Keycloak` — facade: `base_url`, `realm`, optional credentials; lazy `oidc` and
  `admin` sub-clients sharing one `LWP::UserAgent` (injectable via `ua`).
- `WWW::Keycloak::OIDC` — discovery, JWKS, token verification, userinfo, introspection,
  token endpoint helpers, device authorization endpoint.
- `WWW::Keycloak::Admin` — Admin REST API: realms, clients, users, credentials. Direct
  methods (`list_users`, `create_client`), no nested sub-client objects.
- `WWW::Keycloak::Error` — base; `::Validation`, `::Network`, `::API` (with
  `http_status`, `api_message`), one package per file.

## Invariants

- **Shape follows `WWW::Zitadel`.** Same facade, same error hierarchy, same test layout
  (`t/00-load.t`, construction, one file per concern, mocked HTTP, opt-in live suite).
- **Sync/async twin.** `Net::Async::Keycloak` (`~/dev/p5-net-async-keycloak`) mirrors the
  public API with `_f` suffixes returning Futures. This repo leads; an API change here is
  incomplete until the twin has a ticket for it.
- **Keycloak facts are verified, not remembered.** Endpoint paths, payload shapes and
  claim contents differ between Keycloak versions. Before encoding one, check the
  documentation of the targeted version or a running instance, and say which version in
  the POD.
- **The realm is part of the address.** OIDC lives under the realm's issuer; the Admin
  API is addressed per realm. Do not hide the realm in a global.
- **Live tests are opt-in** (`KEYCLOAK_LIVE_TEST=1 KEYCLOAK_URL=…`) and create and remove
  their own throwaway realm. A default `prove -lr t` passes with them skipped.

## Purpose beyond the client

This dist is the basis for an automatic Keycloak setup (realm, clients, users from Perl)
and gives `Airlock` (`~/dev/p5-airlock`) a real Keycloak to be tested against. Airlock
does not depend on this dist at runtime.
