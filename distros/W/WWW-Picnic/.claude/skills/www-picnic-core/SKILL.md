---
name: www-picnic-core
description: Load on any edit in lib/WWW/Picnic/* or bin/picnic* — the API surface, the Result object model, the MockUA test pattern, where the version lives.
---

# WWW::Picnic — Architecture & Implementation Patterns

## Module layout

```
lib/WWW/Picnic.pm                          # main client (Moo), single $VERSION here
lib/WWW/Picnic/Result.pm                   # base — `raw` + `_get($key)` + tolerant BUILDARGS
lib/WWW/Picnic/Result/Login.pm             # user_id, requires_2fa, is_authenticated
lib/WWW/Picnic/Result/User.pm              # profile + address
lib/WWW/Picnic/Result/Cart.pm              # items, total_count, total_price
lib/WWW/Picnic/Result/DeliverySlots.pm     # container + available_slots filter
lib/WWW/Picnic/Result/DeliverySlot.pm      # one slot
lib/WWW/Picnic/Result/Search.pm            # nested-body parser, all_items
lib/WWW/Picnic/Result/SearchResult.pm      # one item
lib/WWW/Picnic/Result/Article.pm           # product detail
bin/picnic, picnic-de, picnic-nl           # CLI wrappers
t/lib/WWW/Picnic/MockUA.pm                 # LWP::UserAgent fake + sample response generators
```

## Versioning — version lives ONLY in the main module

`our $VERSION` belongs in `lib/WWW/Picnic.pm` and **nowhere else in lib/WWW/Picnic/*.pm**. `[@Author::GETTY]` sets `version_finder = :MainModule` so only the main module is rewritten/bumped. Do NOT add `our $VERSION` to a sibling `.pm` file.

The dist is currently ahead of CPAN by exactly one version — repo `$VERSION = '0.101'` while the latest release is `0.100`. When bumping, increment by exactly one and add a bullet under `{{$NEXT}}` in `Changes` in the same change.

## Public API surface — `WWW::Picnic`

Every method that talks to the API lives on the main module and follows this pattern:

```perl
sub get_foo {
  my ( $self ) = @_;
  return WWW::Picnic::Result::Foo->new( $self->request( GET => 'path/to/foo' ) );
}
```

Rules:

- **Always go through `$self->request`** — never build `HTTP::Request` directly in a feature method. Centralising auth headers and JSON encode/decode is the whole point.
- **Always return a typed Result object** for endpoints that have one; the raw hashref leaks via `$obj->raw` if a caller needs an undocumented field.
- **Lowercase method names**: `get_user`, `get_cart`, `clear_cart`, `add_to_cart`, `remove_from_cart`, `set_delivery_slot`, `get_delivery_slots`, `get_article`, `get_categories`, `get_suggestions`, `search`, `login`, `generate_2fa_code`, `verify_2fa_code`, `picnic_auth`, `request`.
- **Search lives at `pages/search-page-results`** with `search_term` as a query parameter (not a body) — the API moved off the old `search` endpoint.

### Auth flow

`login()` does the right thing:

1. POST `user/login` with `{ key, secret (md5_hex of pass), client_id }`.
2. Read `X-Picnic-Auth` response header — that is the auth token, cached on the instance.
3. Return a `WWW::Picnic::Result::Login` — caller inspects `requires_2fa`.
4. If 2FA: caller calls `generate_2fa_code` then `verify_2fa_code($sms_code)`, which itself caches the token on success.
5. `picnic_auth()` returns the cached token or croaks with a hint to handle 2FA manually.

`client_id` defaults to `30100` (Android app); keep that. Required headers on every authenticated request: `X-Picnic-Auth`, `X-Picnic-Agent` (`picnic_agent` attr, default Android UA string), `X-Picnic-Did` (random hex per instance, `picnic_did` attr).

## Result object model

`WWW::Picnic::Result` is the base. It owns one attribute, `raw` (hashref from the API), and exposes `_get($key)` for lazy accessors:

```perl
has firstname => (
  is   => 'ro',
  lazy => 1,
  default => sub { shift->_get('firstname') },
);
```

`BUILDARGS` accepts either a hashref (treated as the raw payload) or a plain hashref that already has `raw => {...}` — both call sites work. This is what lets the main module write `Result::Foo->new( $self->request(...) )` with no wrapping.

Container results (`Search`, `DeliverySlots`) iterate their items and return them as typed objects, not raw hashrefs. Add a `*_items` / `all_items` / `available_slots` accessor that returns objects, and keep the raw array reachable via `->raw->{...}`.

### Search result parsing (nested format)

The live API returns a deeply nested `body.child.children[].child.children[].sellingUnit` shape. `WWW::Picnic::Result::Search` walks that tree to extract `sellingUnit` objects into `all_items`; `WWW::Picnic::Result::SearchResult` wraps each one. Do not flatten this on the client side without checking the real response shape — `MockUA` already mirrors the nested format, so any flattening must keep the test fixtures in sync.

## MockUA pattern (`t/lib/WWW/Picnic/MockUA.pm`)

Tests construct `WWW::Picnic` with `http_agent => $mock_ua`. The fake is a blessed hashref that quacks like `LWP::UserAgent`:

- `add_response($path_pattern, $data, headers => {...})` registers a regex matched against the request URI; first match wins.
- `request($http_request)` records the request in `all_requests`, returns an `HTTP::Response` with JSON body and the configured headers (status defaults to 200).
- Unmatched URIs return a 404 with `{ error => 'Not found', uri => $uri }` so test failures are loud.
- Sample response generators live on the same module: `sample_login_response`, `sample_login_2fa_response`, `sample_user_response`, `sample_cart_response`, `sample_delivery_slots_response`, `sample_search_response`, `sample_article_response`. Add a new generator next to these whenever a new endpoint is added — `t/offline.t` extends them by default.

The `path_pattern` is a regex against `$request->uri->as_string` (the full URL including `https://storefront-prod.de.picnicinternational.com/api/15/...`). Anchor loosely so the API-version segment (`15`) doesn't break tests when bumped.

## CLI — `bin/picnic`, `picnic-de`, `picnic-nl`

- `picnic` is the canonical CLI; `picnic-de` / `picnic-nl` are 2-line wrappers that preset `PICNIC_LANG` / `PICNIC_COUNTRY` env vars.
- All three follow the `use WWW::Picnic;` → `GetOptions` → `%commands` dispatch shape. New command = one entry in `%commands`, plus POD under `__END__`.
- Localisation lives in the `my %I18N` table at the top of `bin/picnic`; `t('key')` falls back to English then the raw key. Add new strings to all three languages (`en`, `de`, `nl`) in the same change.
- `--raw` always prints `$result->raw` as pretty JSON; honour it everywhere.
- 2FA handling is centralised in `do_login()` — every authenticated command calls it.

## Testing — what runs by default

- `t/load.t` — `use_ok` for every module. Add a new module here in the same change.
- `t/offline.t` — full MockUA suite. Every method on `WWW::Picnic` should have at least one assertion here.
- `t/basic.t` — **live** API test, gated on `TEST_WWW_PICNIC_USER` + `TEST_WWW_PICNIC_PASS`. Never runs by default. Treat it as a smoke test against the real Picnic API; keep it fast and tolerant (it may be skipped mid-run on 2FA).

Run command: `prove -lr t` (recursive — the suite is flat today, keep `-r` so any future subdir tests are not silently skipped). `dzil build` / `dzil test` are fine anytime; `dzil release` is forbidden without the maintainer's explicit go-ahead.

## Conventions — silent, non-negotiable

- Moo everywhere. No Moose, no Moose deps.
- `use Module qw(...)` at the top of every `.pm`; no `require` as a "lazy optimisation" (`getty-perl-core`).
- Inline `=attr` / `=method` POD, one per attribute/method; `PodWeaver` generates the boilerplate (`getty-perl-release-author-getty`).
- `Changes` bullet under `{{$NEXT}}` in the SAME change as any user-facing change — new method, new result class, fixed bug, CLI command. Two-space indent, `  - ` bullets, present tense.
- `cpanfile` pins Getty-authored deps to their **latest released CPAN version**, never the repo `$VERSION` (`getty-perl-core`).
