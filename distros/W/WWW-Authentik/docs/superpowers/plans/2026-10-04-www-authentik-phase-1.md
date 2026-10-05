# WWW::Authentik Phase 1 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** `WWW::Authentik` Phase 1 bauen: Fassade, Fehler, die REST-API v3 mit wiederholbaren `ensure_*`-Methoden, OIDC gegen eine Application, Unit-Tests gegen ein nachgebautes authentik und eine Live-Suite gegen ein echtes.

**Architecture:** Moo-Klassen nach dem Muster von `WWW::Keycloak`, aber eigenständig: `WWW::Authentik` ist die Fassade für eine Instanz und optional eine Application und baut `WWW::Authentik::OIDC` und `WWW::Authentik::API` mit einer gemeinsamen `LWP::UserAgent`. Das Senden und das Abbilden von authentiks vier Fehlerformen liegt in der Rolle `WWW::Authentik::Role::HTTP`, aufgeteilt in `build_request` / `read_response` / `send_request`, damit der Zwilling die ersten beiden mitbenutzt. Der Vergleich hinter `ensure_*` ist eine reine Funktion ohne I/O (`WWW::Authentik::Diff`). Keine Abhängigkeit auf `WWW-Keycloak`.

**Tech Stack:** Perl 5.20+, Moo, Types::Standard, LWP::UserAgent, HTTP::Message, JSON::MaybeXS, Crypt::JWT, URI. Dist::Zilla mit `[@Author::GETTY]`.

**Spec:** `docs/superpowers/specs/2026-10-04-www-authentik-design.md` (freigegeben 2026-10-04, mit Abschnitt 12 aus dem Freigabe-Review).

## Stand dieses Plans

Der Plan ist für einen Ausführenden ohne Vorwissen geschrieben, aber er ist **kein
vollständiges Code-Listing** wie der Keycloak-Plan. Vollständig ausgeschrieben ist, was
sich nicht aus der Spec ableiten lässt und wo ein Fehler teuer ist: `Diff`, die
Fehlerklassen und die Abbildung der vier Fehlerformen, die HTTP-Rolle, die
Namensauflösungstabelle, der `_ensure`-Kern, `verify_token` und die Paginierung. Für die
übrigen Methoden nennt der Plan Signatur, HTTP-Aufruf und Rückgabe in Tabellenform; die
Spec-Abschnitte 5.1, 5.2, 6 und 8 sind dafür die Quelle und beim Bauen offen zu halten.
Jede Zeile der Methodentabellen ist in Spec-Abschnitt 8 belegt.

## Global Constraints

- Laufzeit-Abhängigkeiten genau die im `cpanfile` aus Aufgabe 1; nichts aus `WWW-Keycloak`.
- Ein Paket pro Datei, jede Datei unter `lib/` mit `# ABSTRACT:` (nur ASCII) und `our $VERSION = '0.001';`.
- Kein `require` zum verzögerten Laden unter `lib/`.
- `croak` statt `die` in Nicht-Klassen-Hilfscode; jeder Fehler der Dist ist ein Objekt aus `WWW::Authentik::Error::*`, geworfen mit `->throw`.
- Das API-Token erscheint in keiner Fehlermeldung und in keinem Log.
- 2 Leerzeichen Einrückung, keine abschließenden Kommas, `my ( $self, ... ) = @_;` als erste Zeile, Einzeiler mit `$_[0]->`.
- `is => 'ro'` ist der Standard, `is => 'lazy'` mit `sub _build_x` für alles Nichttriviale, `namespace::autoclean` in jeder Klasse, Typen aus `Types::Standard`.
- Es gibt keinen Realm: `base_url` ist Pflicht, `application` (Slug) und `token` sind optional; `oidc` ohne Slug und `api` ohne Token werfen beim ersten Zugriff `WWW::Authentik::Error::Validation`.
- Jeder API-Pfad endet auf `/`; ohne Schrägstrich antwortet authentik 404 (Spec 8.1).
- `ensure_*` vergleicht nur die übergebenen Schlüssel, schreibt nur bei Abweichung, löscht nie etwas und liefert `{ object, changed }` mit `changed` gleich `created`, `updated` oder leer. Die Abweichung von Keycloaks `{ id, changed }` ist gewollt (Spec 12) und steht in der POD der Fassade.
- Schreibend ist `PATCH`, nie `PUT` (Spec 5.1).
- authentik-Verhalten wird nicht aus dem Gedächtnis kodiert: Was `t/lib/FakeAuthentik.pm` tut, ist das in Spec-Abschnitt 8 beobachtete, an authentik 2026.8.3.
- Jede `.t`-Datei beginnt mit `#!/usr/bin/env perl`, `use strict; use warnings; use Test::More;` und endet mit `done_testing;`. Tests laufen mit `prove -lr t`.
- Die Live-Suite läuft nur mit `AUTHENTIK_LIVE_TEST=1`, `AUTHENTIK_URL` und `AUTHENTIK_TOKEN` und nie in einem parallelen Lauf.
- Die Repos sind öffentlich: keine Hostnamen außer `127.0.0.1` und `example.org`, keine Tokens, keine internen Adressen in Dateien oder Commits.

## Review Focus

Fünf Eingaben, die die Spec voraussetzt, die aber keine Aufgabe von sich aus prüfen würde.
Jede bekommt ihren Test in der Aufgabe, der der Code gehört.

1. **Ein Name, der wie eine Kennung aussieht** — ein Provider namens `123`, ein Flow-Slug in UUID-Form. Erwartet: `provider => '123'` ist der PK 123, `provider_name => '123'` schlägt den Namen nach; beides zugleich ist ein Validation-Fehler. Tests `looks like an identifier` in `t/52-api-resolve.t` (Aufgabe 5).
2. **Ein Setup, das zweimal läuft.** Erwartet: beim zweiten Mal kein einziger schreibender Aufruf, `changed` leer, insbesondere bei `property_mappings` (authentik sortiert um) und `redirect_uris` (authentik ergänzt `redirect_uri_type`). Tests `writes nothing on the second run` in `t/51-api-ensure.t` (Aufgabe 5) und `twice` in `t/90-live-authentik.t` (Aufgabe 6).
3. **Ein Passwort im Setup und ein zweiter Lauf.** Erwartet: Das Passwort wird genau einmal gesetzt, beim Anlegen. Test `ensure_user sets the password only when it creates` in `t/51-api-ensure.t` (Aufgabe 5).
4. **Eine Liste mit mehr Treffern, als auf eine Seite passen.** Erwartet: `list_*` liefert alle, folgt `pagination.next`, bricht bei `next: 0` ab und läuft bei einer kaputten Antwort (`next` zeigt zurück) nicht endlos. Test `pagination` in `t/50-api.t` (Aufgabe 4).
5. **Ein Token, das nicht von dieser Application stammt, abgelaufen ist, mit fremdem Schlüssel, mit HMAC oder mit `alg: none` signiert ist.** Erwartet: abgelehnt mit Validation-Fehler; ein Token mit neu rotiertem Schlüssel dagegen angenommen, aber höchstens einmal pro `jwks_min_age` nachgeladen. Tests `verify_token` und `key rotation` in `t/60-oidc.t` (Aufgabe 3).

## Dateien

| Datei | Verantwortung | Aufgabe |
|---|---|---|
| `cpanfile` | Abhängigkeiten | 1 |
| `lib/WWW/Authentik/Diff.pm` | Vergleich ohne I/O, Listen als Mengen, ergänzte Defaults | 1 |
| `t/10-diff.t` | Diff | 1 |
| `lib/WWW/Authentik/Error.pm`, `Error/Validation.pm`, `Error/Network.pm`, `Error/API.pm` | Fehlerhierarchie, vier Fehlerformen | 2 |
| `lib/WWW/Authentik/Role/HTTP.pm` | `build_request`, `read_response`, `send_request` | 2 |
| `t/lib/FakeAuthentik.pm` | nachgebautes authentik für die Unit-Tests | 2 |
| `t/20-errors.t` | Fehlerformen und Prädikate | 2 |
| `lib/WWW/Authentik/OIDC.pm` | Discovery, JWKS, `verify_token`, Token-Endpunkt | 3 |
| `lib/WWW/Authentik.pm` | Fassade (der Stub wird ersetzt) | 3 |
| `t/40-facade.t`, `t/60-oidc.t` | Fassade, OIDC | 3 |
| `lib/WWW/Authentik/API.pm` (Transport, Paginierung, Grundoperationen) | API v3 | 4 |
| `t/50-api.t` | Grundoperationen, Paginierung | 4 |
| `lib/WWW/Authentik/API.pm` (Abschnitt `resolve` und `ensure`) | Namensauflösung, wiederholbare Methoden | 5 |
| `t/51-api-ensure.t`, `t/52-api-resolve.t` | `ensure_*`, Auflösung | 5 |
| `t/lib/AuthentikExecutor.pm`, `t/90-live-authentik.t` | Login per Flow-Executor, Live-Suite | 6 |
| `README.md`, `Changes`, `CLAUDE.md`, `.claude/skills/www-authentik-core/SKILL.md`, `t/00-load.t` | Stand nachziehen | 6 |

Reihenfolge: 1 → 2 → 3 → 4 → 5 → 6, jede baut auf der vorigen auf. Ein Commit je Aufgabe.

---

### Task 1: Abhängigkeiten und `WWW::Authentik::Diff`

**Files:**
- Modify: `cpanfile` (ganz ersetzen)
- Create: `lib/WWW/Authentik/Diff.pm`
- Test: `t/10-diff.t`
- Modify: `t/00-load.t`

**Interfaces:**
- Produces: `WWW::Authentik::Diff->changes( \%current, \%wanted )` → HashRef der zu schreibenden Schlüssel (verschachtelte Hashes zusammengeführt), leer wenn nichts zu tun ist; `->merge( \%current, \%wanted )` → tief zusammengeführter Hash; `->same( $a, $b )` → 1/0; `->list_defaults` → HashRef Feldname → Default-Hash, das authentik bei Listenelementen ergänzt.

- [ ] **Step 1: `cpanfile` ersetzen und installieren**

`cpanfile`:

```perl
requires 'perl', '5.020';
requires 'Crypt::JWT';
requires 'HTTP::Message';
requires 'JSON::MaybeXS';
requires 'LWP::Protocol::https';
requires 'LWP::UserAgent';
requires 'Moo';
requires 'Type::Tiny';
requires 'URI';
requires 'namespace::autoclean', '0.16';

on test => sub {
    requires 'CryptX';
    requires 'Test::More', '0.96';
};
```

Run: `cpanm --installdeps .` — Expected: endet ohne Fehler.

- [ ] **Step 2: `t/10-diff.t` schreiben**

Subtest `same`:
- gleiche und verschiedene Strings; `3600` gegen `'3600'` gleich; `undef`/`undef` gleich; `undef` gegen `''` verschieden.
- Booleans in jeder Schreibweise gleich: `\1`, `JSON::MaybeXS::true`, `'true'`, `1` untereinander; `\1` gegen `\0` verschieden; `'true'` gegen `'yes'` verschieden.
- **Listen sind Mengen**: `[qw( a b )]` gleich `[qw( b a )]`; `[qw( a b )]` verschieden von `[qw( a b b )]`; Listen von Hashes als Menge: `[ { a => 1 }, { b => 2 } ]` gleich `[ { b => 2 }, { a => 1 } ]`; Schlüsselreihenfolge innerhalb eines Hashes egal.
- leere Liste gleich leerer Liste, verschieden von `undef`.

Subtest `changes`:
- nichts zu tun bei gleichem Zustand; ein Schlüssel der obersten Ebene; ein verschachtelter Hash kommt zusammengeführt zurück (`attributes`), ein schon passender verschachtelter Schlüssel ergibt nichts; eine Liste wird ersetzt; ein Schlüssel, den der aktuelle Zustand nicht hat; verschachtelter Hash, wo keiner war; Hash, wo ein Skalar war; `undef` als aktueller Zustand; der aktuelle Zustand wird nicht verändert.
- `property_mappings` in anderer Reihenfolge ergibt **keine** Änderung.
- `redirect_uris`: `[ { matching_mode => 'strict', url => 'https://a/cb' } ]` gegen den gelesenen Zustand `[ { matching_mode => 'strict', url => 'https://a/cb', redirect_uri_type => 'authorization' } ]` ergibt **keine** Änderung; eine andere URL ergibt eine.

Subtest `merge`: tief für Hashes, alles andere ersetzt; `undef` als aktueller Zustand.

- [ ] **Step 3: Test laufen lassen, er muss scheitern**

Run: `prove -lr t/10-diff.t` — Expected: FAIL mit `Can't locate WWW/Authentik/Diff.pm in @INC`.

- [ ] **Step 4: `lib/WWW/Authentik/Diff.pm` schreiben**

```perl
package WWW::Authentik::Diff;

# ABSTRACT: Compare an authentik representation with the wanted state, without I/O

use strict;
use warnings;
use Scalar::Util qw( blessed );
use JSON::MaybeXS;

our $VERSION = '0.001';

my $JSON = JSON::MaybeXS->new( canonical => 1, allow_nonref => 1, convert_blessed => 1 );

sub list_defaults {
  return { redirect_uris => { redirect_uri_type => 'authorization' } };
}

sub changes {
  my ( $self, $current, $wanted, $key_prefix ) = @_;
  $current = {} unless ref $current eq 'HASH';
  my %changes;
  for my $key ( keys %$wanted ) {
    my ( $have, $want ) = ( $current->{$key}, $self->with_defaults( $key, $wanted->{$key} ) );
    if ( ref $want eq 'HASH' ) {
      my $inner = $self->changes( ref $have eq 'HASH' ? $have : {}, $want );
      $changes{$key} = $self->merge( ref $have eq 'HASH' ? $have : {}, $want ) if %$inner;
      next;
    }
    $changes{$key} = $wanted->{$key} unless $self->same( $have, $want );
  }
  return \%changes;
}

sub with_defaults {
  my ( $self, $key, $value ) = @_;
  my $defaults = $self->list_defaults->{$key};
  return $value unless $defaults && ref $value eq 'ARRAY';
  return [ map { ref $_ eq 'HASH' ? { %$defaults, %$_ } : $_ } @$value ];
}

sub merge {
  my ( $self, $current, $wanted ) = @_;
  my %merged = %{ $current || {} };
  for my $key ( keys %$wanted ) {
    $merged{$key} = ref $wanted->{$key} eq 'HASH' && ref $merged{$key} eq 'HASH'
      ? $self->merge( $merged{$key}, $wanted->{$key} )
      : $wanted->{$key};
  }
  return \%merged;
}

sub same {
  my ( $self, $have, $want ) = @_;
  return 1 if !defined $have && !defined $want;
  return 0 if !defined $have || !defined $want;
  my ( $have_bool, $want_bool ) = ( $self->_bool($have), $self->_bool($want) );
  return $have_bool eq $want_bool ? 1 : 0 if defined $have_bool && defined $want_bool
    && ( $self->_is_bool($have) || $self->_is_bool($want) );
  # authentik returns lists in its own order (property_mappings) and the order
  # never carries meaning, so every list is compared as a multiset
  if ( ref $have eq 'ARRAY' && ref $want eq 'ARRAY' ) {
    return 0 unless @$have == @$want;
    my @a = sort map { $JSON->encode($_) } @$have;
    my @b = sort map { $JSON->encode($_) } @$want;
    return $JSON->encode( \@a ) eq $JSON->encode( \@b ) ? 1 : 0;
  }
  return $JSON->encode($have) eq $JSON->encode($want) ? 1 : 0 if ref $have || ref $want;
  return "$have" eq "$want" ? 1 : 0;
}

sub _is_bool {
  my ( $self, $value ) = @_;
  return 1 if ref $value eq 'SCALAR' || ( blessed $value && $value->isa('JSON::PP::Boolean') );
  return 1 if JSON::MaybeXS::is_bool($value);
  return 1 if !ref $value && ( $value eq 'true' || $value eq 'false' );
  return 0;
}

sub _bool {
  my ( $self, $value ) = @_;
  return ${$value} ? 1 : 0 if ref $value eq 'SCALAR';
  return $value ? 1 : 0 if JSON::MaybeXS::is_bool($value);
  return if ref $value;
  return 1 if $value eq 'true' || $value eq '1';
  return 0 if $value eq 'false' || $value eq '0' || $value eq '';
  return;
}

1;
```

POD nach `getty-perl-pod`: `=synopsis` mit `changes`/`merge`, `=description` mit den drei
Regeln (nur die genannten Schlüssel, Listen als Mengen, von authentik ergänzte Defaults),
`=method` für `changes`, `merge`, `same`, `with_defaults`, `list_defaults`.

- [ ] **Step 5: Test laufen lassen**

Run: `prove -lr t/10-diff.t` — Expected: PASS.

- [ ] **Step 6: `t/00-load.t` ergänzen und committen**

`t/00-load.t` listet ab jetzt jedes gebaute Modul; in dieser Aufgabe `WWW::Authentik` und
`WWW::Authentik::Diff`.

Run: `prove -lr t` — Expected: PASS.
Commit: Betreff `Add WWW::Authentik::Diff and the dependencies`, Rumpf eine Zeile je Datei.

---

### Task 2: Fehler, HTTP-Rolle und das nachgebaute authentik

**Files:**
- Create: `lib/WWW/Authentik/Error.pm`, `lib/WWW/Authentik/Error/Validation.pm`, `lib/WWW/Authentik/Error/Network.pm`, `lib/WWW/Authentik/Error/API.pm`, `lib/WWW/Authentik/Role/HTTP.pm`, `t/lib/FakeAuthentik.pm`
- Test: `t/20-errors.t`
- Modify: `t/00-load.t`

**Interfaces:**
- Consumes: nichts.
- Produces:
  - `WWW::Authentik::Error->new( message => $m )`, `->throw( message => $m )`, stringifiziert zu `message`.
  - `WWW::Authentik::Error::API->new( message =>, http_status =>, api_message =>, field_errors =>, oauth_error =>, request_id => )` mit `is_not_found`, `is_forbidden`, `is_unauthorized`, `is_bad_request`.
  - Rolle `WWW::Authentik::Role::HTTP` mit `json_codec`, `api_error_class`, `network_error_class`, `validation_error_class`, `build_request( $method, $url, %arg )`, `read_response( $response, $method, $url, %arg )`, `send_request( $method, $url, %arg )`. `%arg`: `bearer`, `json`, `form`, `basic` (ArrayRef `[ $user, $password ]`). Ergebnis von `read_response`/`send_request`: `{ status, data, location }`.
  - `FakeAuthentik->new( %opt )` ist eine `LWP::UserAgent`-Unterklasse; `->base` liefert `http://ak.test`, `->token` das gültige API-Token, `->requests` die Liste `[ $method, $path, $body ]`, `->writes` die Zahl der schreibenden Aufrufe, `->reset_writes`, `->rotate_key`, `->add( $collection, \%rep )`, `->collection($name)`.

- [ ] **Step 1: `t/lib/FakeAuthentik.pm` schreiben**

Ein `LWP::UserAgent` mit überschriebenem `request`, der authentik 2026.8.3 so beantwortet,
wie Spec-Abschnitt 8 es festhält. Umfang:

*Allgemein*
- Ohne `Authorization` → `403 {"detail":"Authentication credentials were not provided."}`; mit unbekanntem Bearer → `403 {"detail":"Token invalid/expired"}`.
- Pfad ohne abschließenden `/` unter `/api/v3/` → 404.
- Jeder Aufruf wird in `requests` protokolliert; `PATCH`, `POST`, `PUT`, `DELETE` erhöhen `writes`.
- Body nicht-JSON bei `POST`/`PATCH` → `400 {"detail":"JSON parse error - Input data was truncated"}`.

*Sammlungen* mit je einem Schlüsselfeld, einem PK-Feld und einer PK-Form:

| Sammlung | Pfad | Schlüssel | PK-Feld | PK-Form |
|---|---|---|---|---|
| `users` | `/api/v3/core/users/` | `username` | `pk` | Integer, ab 1 |
| `groups` | `/api/v3/core/groups/` | `name` | `pk` | UUID |
| `tokens` | `/api/v3/core/tokens/` | `identifier` | `pk` | UUID, Pfad über `identifier` |
| `applications` | `/api/v3/core/applications/` | `slug` | `pk` | UUID, Pfad über `slug` |
| `providers` | `/api/v3/providers/oauth2/` | `name` | `pk` | Integer |
| `mappings` | `/api/v3/propertymappings/provider/scope/` | `name` | `pk` | UUID |
| `flows` | `/api/v3/flows/instances/` | `slug` | `pk` | UUID, Pfad über `slug` |
| `stages` | `/api/v3/stages/<type>/` und `/api/v3/stages/all/` | `name` | `pk` | UUID, Name über **alle** Typen eindeutig |
| `bindings` | `/api/v3/flows/bindings/` | `(target, stage, order)` | `pk` | UUID |
| `certificates` | `/api/v3/crypto/certificatekeypairs/` | `name` | `pk` | UUID |

Verhalten je Sammlung:
- `GET` Liste: `{"pagination":{...},"results":[...]}`, `page` und `page_size` beachtet, `next` ist die nächste Seitenzahl oder `0`, `count`, `current`, `total_pages`, `start_index`, `end_index`. Exakte Gleichheitsfilter über jeden Query-Parameter, der ein Feld ist; `?page=<zu groß>` → `404 {"detail":"Invalid page."}`.
- `POST`: `201` mit dem ganzen Objekt, PK ergänzt, **kein** `Location`. Doppelter Schlüssel → `400 { "<schlüssel>": [ "… already exists." ] }`, beim Nutzer `["This field must be unique."]`. Fehlendes Pflichtfeld → `400 { "<feld>": ["This field is required."] }` (Provider: `authorization_flow`, `invalidation_flow`, `name`, `redirect_uris`; Application: `name`, `slug`).
- `GET`/`PATCH`/`DELETE` Detail: `200`/`200`/`204`; unbekannt → `404 {"detail":"No <Model> matches the given query."}`; zweites `DELETE` → 404.
- `PATCH` ersetzt `attributes` als Ganzes, ignoriert Lesefelder (`pk`, `uid`, `component`, `assigned_application_slug`, alles auf `_obj`) und unbekannte Felder still.
- Provider: `client_id`/`client_secret` beim Anlegen erzeugt, `grant_types` Standard `[]`, `redirect_uris` bekommen `redirect_uri_type => 'authorization'`, `property_mappings` werden beim Zurückgeben umsortiert (umgedreht genügt), ungültiger `grant_types`-Wert → `400 {"grant_types":{"0":["\"x\" is not a valid choice."]}}`.
- Application: `provider` schon vergeben → `400 {"provider":["Application with this provider already exists."]}`.
- Binding: `(target, stage, order)` doppelt → `400 {"non_field_errors":["The fields target, stage, order must make a unique set."]}`.
- Stage: `not_configured_action => 'configure'` ohne `configuration_stages` → `400 {"not_configured_action":["When \"Not configured action\" is set to \"Configure\", you must set a configuration stage."]}`.
- `POST /api/v3/core/users/{pk}/set_password/` → `204`, merkt das Passwort in `passwords`.
- `POST /api/v3/core/tokens/{id}/set_key/` → `204`; `GET …/view_key/` → `200 {"key": …}`.
- `GET /api/v3/admin/version/` → `200 {"version_current":"2026.8.3", …}`; `GET /api/v3/core/users/me/` → `200 {"user":{…}}`.
- `PATCH /api/v3/stages/all/{uuid}/` → `405 {"detail":"Method \"PATCH\" not allowed."}`.

*OIDC* unter `/application/o/`:
- `GET /application/o/<slug>/.well-known/openid-configuration` → das in Spec 8.2 beobachtete Dokument mit `issuer` = `<base>/application/o/<slug>/`, allen Endpunkten, `claims_supported` mit `amr`, `acr`, `auth_time`; unbekannter Slug → 404.
- `GET /application/o/<slug>/jwks/` → der öffentliche RSA-Schlüssel mit `kid`.
- `POST /application/o/token/`: `client_credentials` (mit `client_secret` oder `username`/`password`), `refresh_token` (rotiert, altes danach ungültig), `authorization_code` (einmalig), `urn:ietf:params:oauth:grant-type:device_code` (erst `authorization_pending`, nach `->approve_device($user_code)` die Tokens). Falsches Secret → `400 invalid_grant`, unbekannter Client → `400 invalid_client`, unbekannter Grant → `400 unsupported_grant_type`, Teilmenge der Scopes beim Refresh → `400 invalid_scope`. Jede Fehlerantwort trägt `request_id`.
- `GET`/`POST /application/o/userinfo/`: `200` mit den Claims, unbekanntes Token → `401` mit leerem Body und `WWW-Authenticate: error="invalid_token", error_description="…"`.
- `POST /application/o/introspect/`: `200 {"active":true, …}` oder `200 {"active":false}` (auch bei falschem Secret).
- `POST /application/o/revoke/`: `200 {}`, auch für Müll; falsches Secret → `401 invalid_client`.
- `POST /application/o/device/` → `{device_code, user_code, verification_uri, verification_uri_complete, expires_in, interval}`.
- Signiert wird mit einem erzeugten RSA-Schlüssel (`Crypt::PK::RSA`, 256 Byte); `->rotate_key` tauscht ihn und vergibt eine neue `kid`. `->sign( \%claims, %opt )` baut ein Token; `%opt` erlaubt `alg => 'none'`, `key => 'hmac'`, `exp`, `iss`, `kid`, damit `t/60-oidc.t` die abzulehnenden Fälle bauen kann.

- [ ] **Step 2: `t/20-errors.t` schreiben**

```perl
#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use lib 't/lib';

use FakeAuthentik;
use WWW::Authentik;

my $fake = FakeAuthentik->new;
my $ak   = WWW::Authentik->new( base_url => $fake->base, application => 'probe-app', token => $fake->token, ua => $fake );

sub error_of (&) { my ( $code ) = @_; eval { $code->(); 1 } ? undef : $@ }

subtest 'classes and stringification' => sub {
  my $e = WWW::Authentik::Error::API->new( message => 'boom', http_status => 400 );
  isa_ok( $e, 'WWW::Authentik::Error' );
  is( "$e", 'boom', 'stringifies to the message' );
  ok( $e->is_bad_request && !$e->is_not_found && !$e->is_forbidden && !$e->is_unauthorized, 'predicates' );
  isa_ok( WWW::Authentik::Error::Validation->new( message => 'x' ), 'WWW::Authentik::Error' );
  isa_ok( WWW::Authentik::Error::Network->new( message => 'x' ), 'WWW::Authentik::Error' );
  isa_ok( error_of { WWW::Authentik::Error::Validation->throw( message => 'thrown' ) }, 'WWW::Authentik::Error::Validation' );
};

subtest 'detail' => sub {
  my $missing = error_of { $ak->api->get_user(999999) };
  isa_ok( $missing, 'WWW::Authentik::Error::API' );
  is( $missing->http_status, 404, 'status as a number' );
  is( $missing->api_message, 'No User matches the given query.', 'detail' );
  ok( $missing->is_not_found, 'is_not_found' );
  is_deeply( $missing->field_errors, {}, 'no field errors' );
  like( "$missing", qr{GET \Qhttp://ak.test/api/v3/core/users/999999/\E failed: 404}, 'message names the request' );
};

subtest 'field errors' => sub {
  $ak->api->create_user( { username => 'alice', name => 'Alice' } );
  my $dup = error_of { $ak->api->create_user( { username => 'alice', name => 'Alice' } ) };
  is( $dup->http_status, 400, '400, not 409' );
  ok( $dup->is_bad_request, 'is_bad_request' );
  is_deeply( $dup->field_errors, { username => ['This field must be unique.'] }, 'field_errors' );
  is( $dup->api_message, 'username: This field must be unique.', 'api_message names the field' );

  my $nested = error_of { $ak->api->update_oauth2_provider( $provider_pk, { grant_types => ['banana'] } ) };
  is_deeply( $nested->field_errors, { 'grant_types.0' => ['"banana" is not a valid choice.'] }, 'nested field errors are flattened' );
};

subtest 'a refused token' => sub {
  my $wrong = WWW::Authentik->new( base_url => $fake->base, token => 'nope', ua => $fake );
  my $error = error_of { $wrong->api->me };
  ok( $error->is_forbidden, '403, not 401' );
  is( $error->api_message, 'Token invalid/expired', 'detail' );
  unlike( "$error", qr/nope/, 'the token is not in the message' );
};

subtest 'the OAuth shape' => sub {
  my $oauth = error_of { $ak->oidc->client_credentials_token( client_id => 'probe', client_secret => 'wrong' ) };
  is( $oauth->oauth_error, 'invalid_grant', 'oauth_error' );
  like( $oauth->api_message, qr/\Ainvalid_grant: /, 'with the description' );
  ok( $oauth->request_id, 'request_id' );
  unlike( "$oauth", qr/wrong/, 'the secret is not in the message' );
};

subtest 'userinfo answers with a header and no body' => sub {
  my $error = error_of { $ak->oidc->userinfo('garbage') };
  is( $error->http_status, 401, '401' );
  ok( $error->is_unauthorized, 'is_unauthorized' );
  is( $error->oauth_error, 'invalid_token', 'oauth_error from WWW-Authenticate' );
};

subtest 'no answer at all' => sub {
  my $down = WWW::Authentik->new( base_url => 'http://127.0.0.1:9', application => 'x', ua => LWP::UserAgent->new( timeout => 2 ) );
  my $error = error_of { $down->oidc->discovery };
  isa_ok( $error, 'WWW::Authentik::Error::Network' );
  like( "$error", qr{GET http://127.0.0.1:9/application/o/x/\.well-known/openid-configuration}, 'names the request' );
};

done_testing;
```

`$provider_pk` entsteht im Subtest `field errors` über `create_oauth2_provider` mit den vier
Pflichtfeldern; die Zeile steht vor dem `my $nested`.

- [ ] **Step 3: Test laufen lassen, er muss scheitern**

Run: `prove -lr t/20-errors.t` — Expected: FAIL, `WWW/Authentik/Error.pm` fehlt.

- [ ] **Step 4: Die Fehlerklassen schreiben**

`lib/WWW/Authentik/Error.pm` wie `WWW::Keycloak::Error`: Moo, `has message`, `overload '""'`,
`sub throw { my ( $class, %arg ) = @_; die $class->new(%arg) }`, **kein** `namespace::autoclean`
(es würde den Overload-Stub entfernen).

`Error/Validation.pm` und `Error/Network.pm`: `use Moo; extends 'WWW::Authentik::Error';` und
`$VERSION`, sonst nichts.

`lib/WWW/Authentik/Error/API.pm`:

```perl
package WWW::Authentik::Error::API;

# ABSTRACT: Raised when authentik answers with an HTTP error

use Moo;
extends 'WWW::Authentik::Error';

our $VERSION = '0.001';

has http_status  => ( is => 'ro', required => 1 );
has api_message  => ( is => 'ro' );
has field_errors => ( is => 'ro', default => sub { {} } );
has oauth_error  => ( is => 'ro' );
has request_id   => ( is => 'ro' );

sub is_bad_request  { $_[0]->http_status == 400 ? 1 : 0 }
sub is_unauthorized { $_[0]->http_status == 401 ? 1 : 0 }
sub is_forbidden    { $_[0]->http_status == 403 ? 1 : 0 }
sub is_not_found    { $_[0]->http_status == 404 ? 1 : 0 }
```

POD: `=description` nennt die vier Fehlerformen aus Spec 7 und warum es kein `is_conflict`
gibt (ein Duplikat ist 400 wie jeder Validierungsfehler); `=attr` für jedes Feld,
`=method` für die vier Prädikate.

- [ ] **Step 5: `lib/WWW/Authentik/Role/HTTP.pm` schreiben**

```perl
package WWW::Authentik::Role::HTTP;

# ABSTRACT: Sending requests to authentik and turning failures into exceptions

use HTTP::Request;
use JSON::MaybeXS;
use MIME::Base64 qw( encode_base64 );
use URI;
use WWW::Authentik::Error::API;
use WWW::Authentik::Error::Network;
use WWW::Authentik::Error::Validation;
use Moo::Role;

our $VERSION = '0.001';

sub json_codec { JSON::MaybeXS->new( utf8 => 1, canonical => 1, convert_blessed => 1 ) }

sub api_error_class        { 'WWW::Authentik::Error::API' }
sub network_error_class    { 'WWW::Authentik::Error::Network' }
sub validation_error_class { 'WWW::Authentik::Error::Validation' }

sub build_request {
  my ( $self, $method, $url, %arg ) = @_;
  my $request = HTTP::Request->new( $method => $url );
  $request->header( Accept => 'application/json' );
  $request->header( Authorization => 'Bearer '.$arg{bearer} ) if defined $arg{bearer};
  $request->header( Authorization => 'Basic '.encode_base64( $arg{basic}[0].':'.$arg{basic}[1], '' ) ) if $arg{basic};
  if ( exists $arg{json} ) {
    $request->header( 'Content-Type' => 'application/json' );
    $request->content( $self->json_codec->encode( $arg{json} ) );
  }
  elsif ( $arg{form} ) {
    my $uri = URI->new('http:');
    $uri->query_form( map { $_ => $arg{form}{$_} } grep { defined $arg{form}{$_} } sort keys %{ $arg{form} } );
    $request->header( 'Content-Type' => 'application/x-www-form-urlencoded' );
    $request->content( $uri->query // '' );
  }
  return $request;
}

sub read_response {
  my ( $self, $response, $method, $url, %arg ) = @_;
  my $content = $response->decoded_content // '';
  my $data    = length $content ? eval { $self->json_codec->decode( $response->content ) } : undef;
  # authentik answers 302 on /application/o/authorize/ and in the flow executor;
  # that is an answer, not a failure
  return { status => $response->code, data => $data, location => scalar $response->header('Location') }
    if $response->code < 400;
  my ( $message, $oauth, $request_id, %fields );
  if ( ref $data eq 'HASH' ) {
    $request_id = $data->{request_id};
    if ( defined $data->{detail} ) {
      $message = $data->{detail};
    }
    elsif ( defined $data->{error} && !ref $data->{error} ) {
      $oauth   = $data->{error};
      $message = $data->{error}.( defined $data->{error_description} ? ': '.$data->{error_description} : '' );
    }
    else {
      %fields  = %{ $self->_flatten_fields($data) };
      $message = join '; ', map { $_.': '.join ', ', @{ $fields{$_} } } sort keys %fields;
    }
  }
  if ( !defined $message && ( my $challenge = $response->header('WWW-Authenticate') ) ) {
    ( $oauth )   = $challenge =~ /error="([^"]+)"/;
    ( $message ) = $challenge =~ /error_description="([^"]+)"/;
    $message = $oauth if !defined $message && defined $oauth;
  }
  $self->api_error_class->throw(
    message      => $method.' '.$url.' failed: '.$response->status_line.( defined $message && length $message ? ' - '.$message : '' ),
    http_status  => $response->code,
    api_message  => $message,
    field_errors => \%fields,
    oauth_error  => $oauth,
    request_id   => $request_id
  );
}

sub _flatten_fields {
  my ( $self, $data, $prefix ) = @_;
  my %flat;
  for my $key ( keys %$data ) {
    my $name  = defined $prefix ? $prefix.'.'.$key : $key;
    my $value = $data->{$key};
    if ( ref $value eq 'HASH' ) { %flat = ( %flat, %{ $self->_flatten_fields( $value, $name ) } ) }
    elsif ( ref $value eq 'ARRAY' ) { $flat{$name} = [ map { ref $_ ? $self->json_codec->encode($_) : $_ } @$value ] }
    else { $flat{$name} = [ defined $value ? $value : '' ] }
  }
  return \%flat;
}

sub send_request {
  my ( $self, $method, $url, %arg ) = @_;
  my $response = $self->ua->request( $self->build_request( $method, $url, %arg ) );
  $self->network_error_class->throw( message => $method.' '.$url.': '.$response->status_line )
    if $response->code == 500 && ( $response->header('Client-Warning') // '' ) eq 'Internal response';
  return $self->read_response( $response, $method, $url, %arg );
}

1;
```

POD: `=description` sagt, dass `build_request` und `read_response` getrennt vom Senden sind,
damit `Net::Async::Authentik` sie mitbenutzt, und dass eine Antwort unter 400 als Erfolg
gilt, weil authentik mit 302 antwortet, wo es weiterleitet. `=method` für jede Methode.
Das Bearer-Token steht in keiner Fehlermeldung — die Meldung nennt nur Methode und URL.

- [ ] **Step 6: Test laufen lassen**

Run: `prove -lr t/20-errors.t` — Expected: PASS. (Der Subtest `field errors` braucht
`create_user` und `create_oauth2_provider` aus Aufgabe 4; bis dahin wird er mit
`$fake`-Rohaufrufen über `$ak->api->call` geschrieben und in Aufgabe 4 auf die Methoden
umgestellt.)

- [ ] **Step 7: `t/00-load.t` ergänzen, committen**

Run: `prove -lr t` — Expected: PASS.
Commit: Betreff `Add the error classes, the HTTP role and the fake authentik`.

---

### Task 3: OIDC und die Fassade

**Files:**
- Create: `lib/WWW/Authentik/OIDC.pm`
- Modify: `lib/WWW/Authentik.pm` (Stub ersetzen)
- Test: `t/40-facade.t`, `t/60-oidc.t`
- Modify: `t/00-load.t`

**Interfaces:**
- Consumes: `WWW::Authentik::Role::HTTP`, die Fehlerklassen, `FakeAuthentik`.
- Produces:
  - `WWW::Authentik->new( base_url =>, application =>, token =>, ua => )` mit `->oidc`, `->api`, `->issuer`, `->application_url`, `->api_url`, `->for_application($slug)`.
  - `WWW::Authentik::OIDC->new( application_url =>, ua =>, algorithms =>, jwks_min_age =>, now => )` mit den Methoden der Tabelle unten.

- [ ] **Step 1: `t/40-facade.t` schreiben**

- `base_url` fehlt oder leer → `WWW::Authentik::Error::Validation` beim Bauen.
- Ein abschließender `/` an `base_url` wird entfernt.
- `issuer` ist `<base_url>/application/o/<slug>/`, `application_url` ohne abschließenden `/`, `api_url` ist `<base_url>/api/v3`.
- Ein Slug wird URI-kodiert (`for_application('a b')`).
- `oidc` ohne `application` → Validation-Fehler, mit → `WWW::Authentik::OIDC`.
- `api` ohne `token` → Validation-Fehler, mit → `WWW::Authentik::API`.
- `for_application('other')` liefert eine neue Fassade mit demselben `ua`-Objekt (`is( $a->ua, $b->ua )`) und demselben Token, aber anderem Slug.
- Die Standard-`ua` folgt keinen Redirects: `is( WWW::Authentik->new( base_url => 'http://x' )->ua->max_redirect, 0 )`.
- `ua` ist injizierbar und wird von `oidc` und `api` geteilt.

- [ ] **Step 2: `t/60-oidc.t` schreiben**

Subtest `discovery and endpoints`: `discovery` holt einmal und merkt sich (zweiter Aufruf
schickt keine zweite Anfrage, geprüft über `$fake->requests`); `issuer` kommt aus dem
Dokument; `token_endpoint`, `userinfo_endpoint`, `introspection_endpoint`,
`revocation_endpoint`, `end_session_endpoint`, `device_endpoint`, `authorization_endpoint`,
`jwks_uri`; ein fehlender Name → Validation-Fehler, der ihn benennt.

Subtest `verify_token`:
- ein frisch signiertes Token wird angenommen, die Claims kommen zurück;
- falscher `iss` → abgelehnt; abgelaufen → abgelehnt; `alg: none` → abgelehnt; HMAC (`HS256`) → abgelehnt; fremder RSA-Schlüssel → abgelehnt; jedes Mal `WWW::Authentik::Error::Validation` mit einer Meldung, die den Grund nennt;
- `audience => 'other'` → abgelehnt, `audience => <client_id>` → angenommen;
- `type => 'access'` nimmt ein Token mit `scope` und lehnt eines ohne ab; `type => 'id'` umgekehrt; ohne `type` wird nichts geprüft;
- `verify_token(undef)` und `verify_token('')` → Validation-Fehler.

Subtest `key rotation`: nach `$fake->rotate_key` wird ein mit dem neuen Schlüssel signiertes
Token angenommen (JWKS werden genau einmal nachgeladen); ein zweites Token mit unbekannter
`kid` innerhalb von `jwks_min_age` löst **keine** weitere JWKS-Anfrage aus (gezählt über
`$fake->requests`); mit vorgestellter Uhr (`now`) danach schon.

Subtest `the token endpoint`: `client_credentials_token` mit Secret und mit
`username`/`password`; `exchange_authorization_code`; `refresh_token` (neues Refresh-Token,
altes danach `invalid_grant`); `device_authorization` (`verification_uri_complete` enthält
den `user_code`); `device_token` vor der Bestätigung wirft mit
`oauth_error eq 'authorization_pending'`, nach `$fake->approve_device` liefert es Tokens;
`userinfo`; `introspect` (`active`); `revoke` (danach `introspect` `active` falsch); ein
fehlender `client_id` → Validation-Fehler.

Subtest `authorization_url`: enthält `response_type=code`, den `client_id`, den kodierten
`redirect_uri`, `scope`, `state`, `nonce`; zusätzliche Parameter werden angehängt; der URL
zeigt auf `authorization_endpoint`.

- [ ] **Step 3: Tests laufen lassen, sie müssen scheitern**

Run: `prove -lr t/40-facade.t t/60-oidc.t` — Expected: FAIL.

- [ ] **Step 4: `lib/WWW/Authentik/OIDC.pm` schreiben**

Attribute: `application_url` (Str, required), `ua` (InstanceOf LWP::UserAgent, required),
`algorithms` (ArrayRef[Str], Standard `RS256 RS384 RS512 PS256 PS384 PS512 ES256 ES384 ES512`),
`jwks_min_age` (Int, 60), `now` (CodeRef, `sub { time }`), `discovery` (lazy, `init_arg undef`),
`_jwks`, `_jwks_fetched` (rw, `init_arg undef`).

```perl
sub _build_discovery {
  my ( $self ) = @_;
  my $data = $self->send_request( GET => $self->application_url.'/.well-known/openid-configuration' )->{data};
  WWW::Authentik::Error::Validation->throw( message => 'discovery for '.$self->application_url.' returned no JSON object' )
    unless ref $data eq 'HASH';
  return $data;
}

sub endpoint {
  my ( $self, $name ) = @_;
  my $url = $self->discovery->{$name};
  WWW::Authentik::Error::Validation->throw( message => 'the discovery document of '.$self->application_url.' has no '.$name )
    unless defined $url;
  return $url;
}

sub issuer                  { $_[0]->endpoint('issuer') }
sub authorization_endpoint  { $_[0]->endpoint('authorization_endpoint') }
sub token_endpoint          { $_[0]->endpoint('token_endpoint') }
sub userinfo_endpoint       { $_[0]->endpoint('userinfo_endpoint') }
sub introspection_endpoint  { $_[0]->endpoint('introspection_endpoint') }
sub revocation_endpoint     { $_[0]->endpoint('revocation_endpoint') }
sub end_session_endpoint    { $_[0]->endpoint('end_session_endpoint') }
sub device_endpoint         { $_[0]->endpoint('device_authorization_endpoint') }
sub jwks_uri                { $_[0]->endpoint('jwks_uri') }
```

`jwks( force_refresh => 1 )` wie bei Keycloak.

```perl
sub verify_token {
  my ( $self, $token, %opt ) = @_;
  WWW::Authentik::Error::Validation->throw( message => 'verify_token needs a token' ) unless defined $token && length $token;
  my %check = (
    token          => $token,
    verify_iss     => $self->issuer,
    verify_exp     => 1,
    accepted_alg   => $self->algorithms,
    decode_payload => 1,
    defined $opt{audience} ? ( verify_aud => $opt{audience} ) : ()
  );
  my $claims = eval { decode_jwt( %check, kid_keys => $self->jwks ) };
  my $error  = $@;
  # a key authentik rotated in since the keys were fetched: fetch them again,
  # but only for that reason and not more often than jwks_min_age allows
  if ( !$claims && $error =~ /kid_keys lookup failed/ && $self->now->() - ( $self->_jwks_fetched // 0 ) >= $self->jwks_min_age ) {
    $claims = eval { decode_jwt( %check, kid_keys => $self->jwks( force_refresh => 1 ) ) };
    $error  = $@;
  }
  $self->_reject( $error =~ s/ at \S+ line \d+.*//sr ) unless $claims;
  if ( defined $opt{type} ) {
    # authentik puts no typ into the header; the access token is the one that
    # carries scope. A heuristic, named as one in the POD.
    my $is_access = exists $claims->{scope} ? 1 : 0;
    $self->_reject( 'not an access token (no scope claim)' ) if $opt{type} eq 'access' && !$is_access;
    $self->_reject( 'not an ID token (it has a scope claim)' ) if $opt{type} eq 'id' && $is_access;
    WWW::Authentik::Error::Validation->throw( message => "verify_token: type must be 'access' or 'id'" )
      unless $opt{type} eq 'access' || $opt{type} eq 'id';
  }
  return $claims;
}
```

Die `=method verify_token`-POD sagt wörtlich, dass `type` eine **Heuristik** ist: authentik
setzt kein `typ` in den Header, beide Tokenarten sind `RS256`-JWTs, und unterschieden wird
am Claim `scope` (Spec 6.1). Ohne `type` wird die Tokenart nicht geprüft.

Token-Endpunkt:

```perl
sub client_credentials_token { my ( $self, %arg ) = @_; $self->_grant( client_credentials => [qw( scope username password )], %arg ) }
sub refresh_token            { my ( $self, $refresh, %arg ) = @_; $self->_grant( refresh_token => [qw( refresh_token scope )], %arg, refresh_token => $refresh ) }
sub exchange_authorization_code { my ( $self, %arg ) = @_; $self->_grant( authorization_code => [qw( code redirect_uri code_verifier )], %arg ) }
sub device_token             { my ( $self, %arg ) = @_; $self->_grant( 'urn:ietf:params:oauth:grant-type:device_code' => ['device_code'], %arg ) }

sub _grant {
  my ( $self, $type, $fields, %arg ) = @_;
  return $self->_token_call( $self->token_endpoint,
    { grant_type => $type, map { $_ => $arg{$_} } grep { defined $arg{$_} } @$fields }, %arg );
}

sub _token_call {
  my ( $self, $url, $form, %arg ) = @_;
  WWW::Authentik::Error::Validation->throw( message => 'a client_id is needed' ) unless defined $arg{client_id};
  my %form = ( %$form, client_id => $arg{client_id}, defined $arg{client_secret} ? ( client_secret => $arg{client_secret} ) : () );
  return $self->send_request( POST => $url, form => \%form )->{data} // {};
}
```

`userinfo($access_token)` ist `GET` auf `userinfo_endpoint` mit Bearer.
`introspect($token, %client)` und `revoke($token, %client)` gehen auf ihre Endpunkte mit
`token` (und `token_type_hint`, wenn gegeben); `revoke` liefert 1.
`device_authorization( client_id =>, scope => )` ruft `_token_call` auf `device_endpoint`.

```perl
sub authorization_url {
  my ( $self, %arg ) = @_;
  WWW::Authentik::Error::Validation->throw( message => 'a client_id is needed' ) unless defined $arg{client_id};
  WWW::Authentik::Error::Validation->throw( message => 'a redirect_uri is needed' ) unless defined $arg{redirect_uri};
  my $uri = URI->new( $self->authorization_endpoint );
  $uri->query_form(
    response_type => $arg{response_type} // 'code',
    ( map { $_ => $arg{$_} } grep { defined $arg{$_} } qw( client_id redirect_uri scope state nonce code_challenge code_challenge_method prompt max_age acr_values ) )
  );
  return $uri->as_string;
}
```

- [ ] **Step 5: `lib/WWW/Authentik.pm` ersetzen**

```perl
package WWW::Authentik;

# ABSTRACT: Perl client for the authentik identity provider (OIDC + REST API v3)

use Moo;
use LWP::UserAgent;
use Types::Standard qw( InstanceOf Str );
use URI::Escape qw( uri_escape_utf8 );
use WWW::Authentik::API;
use WWW::Authentik::Error;
use WWW::Authentik::Error::API;
use WWW::Authentik::Error::Network;
use WWW::Authentik::Error::Validation;
use WWW::Authentik::OIDC;
use namespace::autoclean;

our $VERSION = '0.001';

has base_url    => ( is => 'ro', isa => Str, required => 1 );
has application => ( is => 'ro', isa => Str, predicate => 'has_application' );
has token       => ( is => 'ro', isa => Str, predicate => 'has_token' );

has ua => ( is => 'lazy', isa => InstanceOf['LWP::UserAgent'] );

sub _build_ua {
  # no redirects: authentik answers 302 where it wants a browser, and none of
  # those may carry the API token anywhere
  return LWP::UserAgent->new( timeout => 30, agent => 'WWW-Authentik/'.$VERSION,
    max_redirect => 0, ssl_opts => { verify_hostname => 1 } );
}

has oidc => ( is => 'lazy', init_arg => undef );
has api  => ( is => 'lazy', init_arg => undef );

sub _build_oidc {
  my ( $self ) = @_;
  WWW::Authentik::Error::Validation->throw( message => __PACKAGE__.'->oidc needs an application slug' )
    unless $self->has_application && length $self->application;
  return WWW::Authentik::OIDC->new( application_url => $self->application_url, ua => $self->ua );
}

sub _build_api {
  my ( $self ) = @_;
  WWW::Authentik::Error::Validation->throw( message => __PACKAGE__.'->api needs an API token' )
    unless $self->has_token && length $self->token;
  return WWW::Authentik::API->new( base_url => $self->base_url, token => $self->token, ua => $self->ua );
}

around BUILDARGS => sub {
  my ( $orig, $class, @args ) = @_;
  my $args = $class->$orig(@args);
  $args->{base_url} =~ s{/+\z}{} if defined $args->{base_url};
  return $args;
};

sub BUILD {
  my ( $self ) = @_;
  WWW::Authentik::Error::Validation->throw( message => __PACKAGE__.' needs a base_url' ) unless length $self->base_url;
  return;
}

sub api_url          { $_[0]->base_url.'/api/v3' }
sub application_url  { $_[0]->base_url.'/application/o/'.uri_escape_utf8( $_[0]->application ) }
sub issuer           { $_[0]->application_url.'/' }

sub for_application {
  my ( $self, $slug ) = @_;
  return ref($self)->new(
    base_url    => $self->base_url,
    application => $slug,
    ua          => $self->ua,
    $self->has_token ? ( token => $self->token ) : ()
  );
}

1;
```

POD: `=synopsis` mit beiden Seiten; `=description` nennt, dass es keinen Realm gibt, dass
die API instanzweit und OIDC je Application liegt, dass das API-Token langlebig ist und
nicht erneuert wird — **und** den Unterschied für Umsteiger von `WWW::Keycloak`:
`ensure_*` liefert `{ object, changed }` statt `{ id, changed }`, und `create_*`/`update_*`
liefern die Repräsentation statt einer ID, weil authentik keine einheitliche Kennung hat
(Slug, Integer-PK, UUID, Identifier) und beim Anlegen das ganze Objekt zurückgibt.
`=attr`/`=method` für jedes Attribut und jede Methode; `issuer` sagt, dass es die
Adressform ist (`issuer_mode: per_provider`) und dass `WWW::Authentik::OIDC->issuer` der
maßgebliche Wert aus dem Discovery-Dokument ist.

- [ ] **Step 6: Tests laufen lassen, `t/00-load.t` ergänzen, committen**

Run: `prove -lr t` — Expected: PASS.
Commit: Betreff `Add the OIDC client and the facade`.

---

### Task 4: `WWW::Authentik::API` — Transport, Paginierung, Grundoperationen

**Files:**
- Create: `lib/WWW/Authentik/API.pm`
- Test: `t/50-api.t`
- Modify: `t/00-load.t`, `t/20-errors.t` (Rohaufrufe auf die Methoden umstellen)

**Interfaces:**
- Consumes: `WWW::Authentik::Role::HTTP`, die Fehlerklassen.
- Produces: `WWW::Authentik::API->new( base_url =>, token =>, ua => )` mit
  `call( $method, $path, \%body )` → `{ status, data, location }`,
  `_paged( $path, %query )` → ArrayRef aller Treffer, und den Methoden der Tabelle.
  `diff_class` → `'WWW::Authentik::Diff'`.

- [ ] **Step 1: `t/50-api.t` schreiben**

Subtest `transport`:
- `call( GET => '/core/users/' )` baut `http://ak.test/api/v3/core/users/` und schickt den Bearer;
- ein Pfad ohne führenden `/` wird ergänzt, ein fehlender abschließender `/` wird **nicht** ergänzt (die Methoden setzen ihn; ein roher Aufruf bekommt, was er bestellt, und authentik antwortet dann 404 — der Test prüft genau das);
- ohne Token wirft schon `WWW::Authentik->new(...)->api` (Aufgabe 3).

Subtest `pagination`:
- 25 Nutzer im Fake, `page_size => 10` → `list_users` liefert 25 in einem Aufruf des Aufrufers und drei HTTP-Anfragen;
- `pagination.next` gleich 0 beendet; eine leere Liste ergibt `[]`;
- **eine kaputte Antwort, deren `next` auf eine schon geholte Seite zeigt, bricht ab statt endlos zu laufen** (`$fake->break_pagination` lässt `next` immer auf 1 zeigen; erwartet: höchstens so viele Anfragen wie `total_pages`, dann Rückgabe).

Subtest `users`: `create_user`, `find_user` (exakt, groß/klein unterscheidend: `Probe-Bob`
findet nicht `probe-bob`), `get_user`, `update_user` (PATCH, `attributes` ersetzt),
`set_password`, `delete_user`, `delete_user` ein zweites Mal wirft `is_not_found`,
`create_service_account` liefert `token`.

Subtest `applications and providers`: `create_oauth2_provider` ohne Pflichtfelder wirft mit
`field_errors` für alle vier; vollständig angelegt kommt `client_id`, `client_secret`,
`grant_types => []` zurück; `find_oauth2_provider` über den Namen; `create_application` mit
`provider`; `find_application` über den Slug; ein zweiter Provider an derselben Application
wirft; `provider_setup_urls`.

Subtest `the rest`: je ein Durchlauf `create`/`find`/`update`/`delete` für Gruppen,
Scope-Mappings, Flows, Stages (`password`), Bindings, Tokens (mit `view_token_key` und
`set_token_key`); `list_stages` liest über `/stages/all/`, `update_stage` über den
typisierten Pfad; `update_stage( all => ... )` ist ein Validation-Fehler, weil `/stages/all/`
nur lesen kann.

Subtest `instance`: `version`, `config`, `settings`, `me`.

- [ ] **Step 2: Test laufen lassen, er muss scheitern**

Run: `prove -lr t/50-api.t` — Expected: FAIL, `WWW/Authentik/API.pm` fehlt.

- [ ] **Step 3: Den Transportteil schreiben**

```perl
package WWW::Authentik::API;

# ABSTRACT: authentik REST API v3 with idempotent ensure methods

use Moo;
with 'WWW::Authentik::Role::HTTP';
use Scalar::Util qw( blessed );
use Types::Standard qw( InstanceOf Str );
use URI::Escape qw( uri_escape_utf8 );
use WWW::Authentik::Diff;
use WWW::Authentik::Error;
use WWW::Authentik::Error::Validation;
use namespace::autoclean;

our $VERSION = '0.001';

has base_url => ( is => 'ro', isa => Str, required => 1 );
has token    => ( is => 'ro', isa => Str, required => 1 );
has ua       => ( is => 'ro', isa => InstanceOf['LWP::UserAgent'], required => 1 );

has page_size => ( is => 'ro', default => 100 );

sub diff_class { 'WWW::Authentik::Diff' }

sub api_url { $_[0]->base_url.'/api/v3' }

sub call {
  my ( $self, $method, $path, $body ) = @_;
  $path = '/'.$path unless $path =~ m{\A/};
  my %arg = defined $body ? ( json => $body ) : ();
  return $self->send_request( $method, $self->api_url.$path, %arg, bearer => $self->token );
}

sub _data { $_[0]->call( @_[ 1 .. $#_ ] )->{data} }
sub _done { $_[0]->call( @_[ 1 .. $#_ ] ); 1 }
sub _esc  { uri_escape_utf8( $_[1] ) }

sub _query {
  my ( $self, %query ) = @_;
  return '' unless %query;
  return '?'.join '&', map { $self->_esc($_).'='.$self->_esc( $query{$_} ) }
    grep { defined $query{$_} } sort keys %query;
}

sub _paged {
  my ( $self, $path, %query ) = @_;
  my $page_size = delete $query{page_size} // $self->page_size;
  my ( @all, %seen );
  my $page = 1;
  while ( defined $page && $page > 0 && !$seen{$page}++ ) {
    my $data = $self->_data( GET => $path.$self->_query( %query, page => $page, page_size => $page_size ) );
    last unless ref $data eq 'HASH';
    push @all, @{ $data->{results} || [] };
    $page = $data->{pagination} ? $data->{pagination}{next} : 0;
  }
  return \@all;
}

sub _missing {
  my ( $self, $error ) = @_;
  return 1 if blessed $error && $error->isa('WWW::Authentik::Error::API') && $error->is_not_found;
  die $error;
}

sub _find_one {
  my ( $self, $list, $key, $value ) = @_;
  my ( $found ) = grep { defined $_->{$key} && $_->{$key} eq $value } @$list;
  return $found;
}
```

`%seen` ist der Abbruch gegen eine Antwort, deren `next` zurückzeigt (Review Focus 4).

- [ ] **Step 4: Die Grundoperationen schreiben**

Jede Zeile ist ein Einzeiler oder ein kurzer Block nach demselben Muster. Pfade und
Verhalten aus Spec 5.1 und 8.1.

| Methode | Aufruf |
|---|---|
| `version` | `GET /admin/version/` |
| `config` | `GET /root/config/` |
| `settings` | `GET /admin/settings/` |
| `me` | `GET /core/users/me/` |
| `list_users(%q)` | `_paged('/core/users/', %q)` |
| `find_user($username)` | `_find_one( list_users( username => $u ), 'username', $u )` |
| `get_user($pk)` | `GET /core/users/{pk}/` |
| `create_user(\%rep)` | `POST /core/users/` → Objekt |
| `update_user($pk, \%c)` | `PATCH /core/users/{pk}/` → Objekt |
| `delete_user($pk)` | `DELETE /core/users/{pk}/` → 1 |
| `set_password($pk, $pw)` | `POST /core/users/{pk}/set_password/` `{password}` → 1 |
| `create_service_account(name =>, %opt)` | `POST /core/users/service_account/` → Objekt mit `token` |
| `list_authenticators($pk)` | `GET /authenticators/admin/all/?user={pk}` (liefert eine nackte Liste, keine Paginierung) |
| `list_groups`, `find_group($name)`, `get_group($uuid)`, `create_group`, `update_group`, `delete_group` | `/core/groups/` |
| `add_user_to_group($uuid, $pk)`, `remove_user_from_group($uuid, $pk)` | `POST …/add_user/`, `…/remove_user/` `{pk}` → 1 |
| `list_tokens`, `get_token($id)`, `create_token`, `update_token`, `delete_token` | `/core/tokens/`, Detailpfad über `identifier` |
| `view_token_key($id)` | `GET /core/tokens/{id}/view_key/` → `{key}` |
| `set_token_key($id, $key)` | `POST /core/tokens/{id}/set_key/` → 1 |
| `list_applications`, `find_application($slug)`, `create_application`, `update_application($slug, \%c)`, `delete_application($slug)` | `/core/applications/`, Detailpfad über `slug`; `find_application` fängt die 404 über `_missing` |
| `check_access($slug, %opt)` | `GET /core/applications/{slug}/check_access/` |
| `list_oauth2_providers`, `find_oauth2_provider($name)`, `get_oauth2_provider($pk)`, `create_oauth2_provider`, `update_oauth2_provider`, `delete_oauth2_provider` | `/providers/oauth2/` |
| `provider_setup_urls($pk)` | `GET /providers/oauth2/{pk}/setup_urls/` |
| `preview_user($pk, $user_pk)` | `GET /providers/oauth2/{pk}/preview_user/?for_user={user_pk}` |
| `list_scope_mappings`, `find_scope_mapping($name)`, `create_scope_mapping`, `update_scope_mapping`, `delete_scope_mapping` | `/propertymappings/provider/scope/` |
| `find_scope_mappings_by_scope(@names)` | eine Liste je Name über `?scope_name=`, Reihenfolge der Namen beibehalten; ein Name ohne Treffer → Validation-Fehler, der ihn benennt |
| `test_property_mapping($uuid, %arg)` | `POST /propertymappings/all/{uuid}/test/` |
| `list_flows`, `find_flow($slug)`, `create_flow`, `update_flow($slug, \%c)`, `delete_flow($slug)` | `/flows/instances/`, Detailpfad über `slug` |
| `export_flow($slug)` | `GET /flows/instances/{slug}/export/`; die Antwort ist YAML, kein JSON — der rohe Rumpf wird als String zurückgegeben |
| `stage_types` | `GET /stages/all/types/` |
| `list_stages(%q)` | `_paged('/stages/all/', %q)` |
| `find_stage($name)` | über `list_stages`, `name` ist über alle Typen eindeutig |
| `get_stage($type, $uuid)`, `create_stage($type, \%rep)`, `update_stage($type, $uuid, \%c)`, `delete_stage($type, $uuid)` | `/stages/{type}/…`; `$type` gleich `all` → Validation-Fehler („/stages/all/ can only be read“) |
| `list_bindings(%q)`, `create_binding`, `update_binding($uuid, \%c)`, `delete_binding($uuid)` | `/flows/bindings/`; `list_bindings( target => $uuid )` |
| `list_brands`, `current_brand`, `update_brand($uuid, \%c)` | `/core/brands/`, `/core/brands/current/` |
| `list_certificates`, `find_certificate($name)` | `/crypto/certificatekeypairs/` |
| `list_blueprints`, `get_blueprint($uuid)`, `create_blueprint`, `apply_blueprint($uuid)`, `delete_blueprint($uuid)` | `/managed/blueprints/` |

`export_flow` braucht einen eigenen Weg am JSON-Decoder vorbei: `send_request` liefert
`data => undef`, weil die Antwort YAML ist. Die Methode holt den rohen Rumpf über einen
eigenen `build_request`/`$self->ua->request`-Aufruf und gibt `$response->decoded_content`
zurück; bei Status ab 400 geht sie durch `read_response`, damit der Fehler dieselbe Form hat.

Jede Methode bekommt ihre `=method`-POD mit einer Aufrufzeile und dem, was sie zurückgibt.

- [ ] **Step 5: Tests laufen lassen, `t/20-errors.t` umstellen**

Run: `prove -lr t` — Expected: PASS.

- [ ] **Step 6: `t/00-load.t` ergänzen, committen**

Commit: Betreff `Add the API v3 client with the basic operations`.

---

### Task 5: Namensauflösung und `ensure_*`

**Files:**
- Modify: `lib/WWW/Authentik/API.pm` (Abschnitte `resolve` und `ensure` anfügen)
- Test: `t/51-api-ensure.t`, `t/52-api-resolve.t`

**Interfaces:**
- Consumes: alles aus Aufgabe 4, `WWW::Authentik::Diff`.
- Produces: `resolvable_fields` → HashRef; `resolve( \%rep )` → neuer Hash mit aufgelösten
  Feldern; `ensure_application`, `ensure_oauth2_provider`, `ensure_scope_mapping`,
  `ensure_user`, `ensure_group`, `ensure_token`, `ensure_flow`, `ensure_stage($type, %rep)`,
  `ensure_binding(%arg)`, jede liefert `{ object => \%rep, changed => 'created'|'updated'|'' }`.

- [ ] **Step 1: `t/52-api-resolve.t` schreiben**

```perl
subtest 'looks like an identifier' => sub {
  $api->create_oauth2_provider( { name => '123', authorization_flow => $flow, invalidation_flow => $flow,
    redirect_uris => [ { matching_mode => 'strict', url => 'http://127.0.0.1:1/cb' } ] } );   # pk 1
  $api->create_oauth2_provider( { name => 'real', ... } );                                     # pk 123 im Fake erzwungen

  is( $api->resolve( { provider => '123' } )->{provider}, '123', 'an integer is the pk, never a name' );
  is( $api->resolve( { provider_name => '123' } )->{provider}, 1, 'the _name form always looks the name up' );
  is( $api->resolve( { provider => 'real' } )->{provider}, 123, 'anything that is not an integer is a name' );
  my $both = error_of { $api->resolve( { provider => 1, provider_name => 'real' } ) };
  isa_ok( $both, 'WWW::Authentik::Error::Validation' );
  like( "$both", qr/provider and provider_name/, 'both at once is refused' );
  my $gone = error_of { $api->resolve( { provider_name => 'nope' } ) };
  like( "$gone", qr/no oauth2 provider named "nope"/, 'a name without a match names the field and the value' );
};

subtest 'uuid fields' => sub {
  # a flow whose slug has the shape of a UUID
  my $slugged = $api->create_flow( { name => 'x', slug => '11111111-2222-3333-4444-555555555555',
    title => 'x', designation => 'authentication' } );
  is( $api->resolve( { authorization_flow => '11111111-2222-3333-4444-555555555555' } )->{authorization_flow},
      '11111111-2222-3333-4444-555555555555', 'a UUID shape is the pk' );
  is( $api->resolve( { authorization_flow_slug => '11111111-2222-3333-4444-555555555555' } )->{authorization_flow},
      $slugged->{pk}, 'the _slug form looks the slug up even when it looks like a UUID' );
  is( $api->resolve( { authorization_flow => 'default-authentication-flow' } )->{authorization_flow},
      $default_flow_pk, 'anything else is a slug' );
};

subtest 'lists and scopes' => sub {
  is_deeply( $api->resolve( { groups => [ $uuid, 'probe-group' ] } )->{groups}, [ $uuid, $group_pk ], 'mixed list' );
  is_deeply( $api->resolve( { group_names => ['probe-group'] } )->{groups}, [ $group_pk ], 'the forced form' );
  is_deeply( $api->resolve( { scopes => [qw( openid email )] } )->{property_mappings}, [ $openid_pk, $email_pk ], 'scopes become property_mappings' );
  my $clash = error_of { $api->resolve( { scopes => ['openid'], property_mappings => [$uuid] } ) };
  like( "$clash", qr/scopes and property_mappings/, 'scopes together with property_mappings is refused' );
};
```

- [ ] **Step 2: `t/51-api-ensure.t` schreiben**

Für jede `ensure_*`-Methode:
- erster Lauf `created`, `object` trägt die Kennung;
- zweiter Lauf mit denselben Argumenten: `changed` leer **und `$fake->writes` unverändert** (die Zählung ist der eigentliche Test, Review Focus 2);
- ein geänderter Schlüssel: `updated`, genau ein schreibender Aufruf, die nicht genannten Felder bleiben.

Dazu im Einzelnen:
- `ensure_user`: `attributes` werden zusammengeführt, nicht ersetzt; **`password` wird nur beim Anlegen gesetzt** — der zweite Lauf mit demselben `password` ruft `set_password` nicht (`$fake->requests` enthält genau ein `set_password`); `groups` als Namensliste.
- `ensure_oauth2_provider`: `scopes` statt `property_mappings`; die von authentik umsortierte Liste ergibt beim zweiten Lauf nichts; `redirect_uris` ohne `redirect_uri_type` ergeben beim zweiten Lauf nichts; **ohne `grant_types` beim Anlegen ein Validation-Fehler**, der sagt warum; mit vorhandenem Provider ist `grant_types` nicht nötig.
- `ensure_application`: `provider_name`; ein Slug, der schon mit anderem Namen existiert, wird aktualisiert, nicht neu angelegt.
- `ensure_token`: `expires` als Argument ist ein Validation-Fehler (authentik ignoriert es, Spec 5.2); `expiring => \0` geht.
- `ensure_stage`: `not_configured_action` und `configuration_stages` kommen in **einem** PATCH (geprüft über `$fake->requests`).
- `ensure_binding`: `flow` und `stage` als Slug und Name; ein zweiter Lauf mit derselben `order` ändert nichts; eine andere `order` aktualisiert die vorhandene Bindung, statt eine zweite anzulegen.
- `ensure_*` löscht nichts: ein Feld, das der aktuelle Zustand hat und der gewünschte nicht, bleibt.

- [ ] **Step 3: Tests laufen lassen, sie müssen scheitern**

Run: `prove -lr t/51-api-ensure.t t/52-api-resolve.t` — Expected: FAIL.

- [ ] **Step 4: Den Abschnitt `resolve` schreiben**

```perl
####  resolve

my $UUID    = qr{\A[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}\z};
my $INTEGER = qr{\A[0-9]+\z};

sub resolvable_fields {
  return {
    provider            => { force => 'provider_name',            raw => $INTEGER, find => 'find_oauth2_provider', what => 'oauth2 provider' },
    authorization_flow  => { force => 'authorization_flow_slug',  raw => $UUID,    find => 'find_flow',            what => 'flow' },
    invalidation_flow   => { force => 'invalidation_flow_slug',   raw => $UUID,    find => 'find_flow',            what => 'flow' },
    authentication_flow => { force => 'authentication_flow_slug', raw => $UUID,    find => 'find_flow',            what => 'flow' },
    configure_flow      => { force => 'configure_flow_slug',      raw => $UUID,    find => 'find_flow',            what => 'flow' },
    signing_key         => { force => 'signing_key_name',         raw => $UUID,    find => 'find_certificate',     what => 'certificate' },
    encryption_key      => { force => 'encryption_key_name',      raw => $UUID,    find => 'find_certificate',     what => 'certificate' },
    user                => { force => 'user_name',                raw => $INTEGER, find => 'find_user',            what => 'user' },
    groups              => { force => 'group_names',              raw => $UUID,    find => 'find_group',           what => 'group', list => 1 },
    property_mappings   => { force => 'property_mapping_names',   raw => $UUID,    find => 'find_scope_mapping',   what => 'scope mapping', list => 1 }
  };
}

sub resolve {
  my ( $self, $rep ) = @_;
  my %out    = %$rep;
  my $fields = $self->resolvable_fields;
  if ( exists $out{scopes} ) {
    WWW::Authentik::Error::Validation->throw( message => 'give either scopes or property_mappings, not both' )
      if exists $out{property_mappings} || exists $out{property_mapping_names};
    $out{property_mappings} = [ map { $_->{pk} } @{ $self->find_scope_mappings_by_scope( @{ delete $out{scopes} } ) } ];
  }
  for my $field ( sort keys %$fields ) {
    my $spec = $fields->{$field};
    my $forced = exists $out{ $spec->{force} };
    WWW::Authentik::Error::Validation->throw( message => 'give either '.$field.' or '.$spec->{force}.', not both' )
      if $forced && exists $out{$field};
    next unless $forced || exists $out{$field};
    my $value = $forced ? delete $out{ $spec->{force} } : $out{$field};
    next unless defined $value;
    $out{$field} = $spec->{list}
      ? [ map { $self->_resolve_one( $field, $spec, $_, $forced ) } @{ ref $value eq 'ARRAY' ? $value : [$value] } ]
      : $self->_resolve_one( $field, $spec, $value, $forced );
  }
  return \%out;
}

sub _resolve_one {
  my ( $self, $field, $spec, $value, $forced ) = @_;
  return $value if !$forced && $value =~ $spec->{raw};
  my $find  = $spec->{find};
  my $found = $self->$find($value);
  WWW::Authentik::Error::Validation->throw( message => 'cannot set '.$field.': no '.$spec->{what}.' named "'.$value.'"' )
    unless $found;
  return $found->{pk};
}
```

Die `=method resolve`-POD führt die Tabelle auf: je Feld, was als rohe Kennung gilt
(Integer-PK oder UUID-Form) und wie der Name erzwungen wird (`<feld>_name` beziehungsweise
`<feld>_slug`). Sie sagt ausdrücklich, dass ein Provider namens `123` über `provider_name`
angesprochen werden muss, weil `provider => '123'` der PK 123 ist — und dass beides zugleich
abgelehnt wird.

- [ ] **Step 5: Den Abschnitt `ensure` schreiben**

```perl
####  ensure

sub _ensure {
  my ( $self, %arg ) = @_;
  my $current = $arg{find}->();
  unless ( $current ) {
    my $object = $arg{create}->();
    $arg{after_create}->($object) if $arg{after_create};
    return { object => $object, changed => 'created' };
  }
  my $changes = $self->diff_class->changes( $current, $arg{wanted} );
  return { object => $current, changed => '' } unless %$changes;
  return { object => $arg{update}->( $current, $changes ), changed => 'updated' };
}
```

Jede `ensure_*`-Methode ist dann:
1. Pflichtschlüssel prüfen (Validation-Fehler, wenn er fehlt);
2. `my $rep = $self->resolve( \%rep )`;
3. Hilfsschlüssel aus dem Vergleich nehmen (`password` beim Nutzer);
4. `_ensure` mit `find`, `create`, `update`, `wanted`.

Die Besonderheiten je Methode:

```perl
sub ensure_user {
  my ( $self, %rep ) = @_;
  WWW::Authentik::Error::Validation->throw( message => 'ensure_user needs a username' ) unless defined $rep{username};
  my $wanted   = $self->resolve( \%rep );
  my $password = delete $wanted->{password};   # not a field of the user
  return $self->_ensure(
    wanted => $wanted,
    find   => sub { $self->find_user( $rep{username} ) },
    create => sub { $self->create_user($wanted) },
    # a password is set when the user is created and never again; call
    # set_password to change one
    after_create => sub { $self->set_password( $_[0]{pk}, $password ) if defined $password },
    update => sub { $self->update_user( $_[0]{pk}, $_[1] ) }
  );
}

sub ensure_oauth2_provider {
  my ( $self, %rep ) = @_;
  WWW::Authentik::Error::Validation->throw( message => 'ensure_oauth2_provider needs a name' ) unless defined $rep{name};
  my $wanted = $self->resolve( \%rep );
  return $self->_ensure(
    wanted => $wanted,
    find   => sub { $self->find_oauth2_provider( $rep{name} ) },
    create => sub {
      # a provider created without grant_types answers every token request
      # with invalid_grant, and this client does not guess which grants were meant
      WWW::Authentik::Error::Validation->throw( message => 'ensure_oauth2_provider needs grant_types to create a provider: '
        .'authentik defaults them to an empty list, and such a provider answers every token request with invalid_grant' )
        unless $wanted->{grant_types} && @{ $wanted->{grant_types} };
      $self->create_oauth2_provider($wanted);
    },
    update => sub { $self->update_oauth2_provider( $_[0]{pk}, $_[1] ) }
  );
}

sub ensure_token {
  my ( $self, %rep ) = @_;
  WWW::Authentik::Error::Validation->throw( message => 'ensure_token needs an identifier' ) unless defined $rep{identifier};
  # authentik ignores expires and sets it to now plus default_token_duration
  WWW::Authentik::Error::Validation->throw( message => 'ensure_token cannot set expires: authentik ignores it '
    .'and sets it from the instance setting default_token_duration; use expiring to say whether the token expires at all' )
    if exists $rep{expires};
  ...
}

sub ensure_binding {
  my ( $self, %arg ) = @_;
  for (qw( flow stage order )) {
    WWW::Authentik::Error::Validation->throw( message => 'ensure_binding needs '.$_ ) unless defined $arg{$_};
  }
  my $flow  = $arg{flow}  =~ $UUID ? $arg{flow}  : ( $self->find_flow( $arg{flow} )   || WWW::Authentik::Error::Validation->throw( message => 'ensure_binding: no flow "'.$arg{flow}.'"' ) )->{pk};
  my $stage = $arg{stage} =~ $UUID ? $arg{stage} : ( $self->find_stage( $arg{stage} ) || WWW::Authentik::Error::Validation->throw( message => 'ensure_binding: no stage "'.$arg{stage}.'"' ) )->{pk};
  my %wanted = ( %arg, target => $flow, stage => $stage );
  delete @wanted{qw( flow )};
  return $self->_ensure(
    wanted => \%wanted,
    # a flow binds a stage at most once; the order is what ensure changes
    find   => sub { $self->_find_one( $self->list_bindings( target => $flow, stage => $stage ), 'stage', $stage ) },
    create => sub { $self->create_binding( \%wanted ) },
    update => sub { $self->update_binding( $_[0]{pk}, $_[1] ) }
  );
}
```

`ensure_application` (Schlüssel `slug`), `ensure_group` (`name`), `ensure_scope_mapping`
(`name`), `ensure_flow` (`slug`) und `ensure_stage( $type, %rep )` (`name`, gesucht über
`find_stage`, angelegt und geändert über den typisierten Pfad) folgen dem Muster ohne
Besonderheit.

Jede bekommt ihre `=method`-POD mit Aufrufbeispiel, dem Schlüssel, über den gesucht wird,
und der Rückgabe `{ object, changed }`.

- [ ] **Step 6: Tests laufen lassen, committen**

Run: `prove -lr t` — Expected: PASS.
Commit: Betreff `Add name resolution and the ensure methods`.

---

### Task 6: Live-Suite, Executor-Hilfsmodul, Stand nachziehen

**Files:**
- Create: `t/lib/AuthentikExecutor.pm`, `t/90-live-authentik.t`
- Modify: `README.md`, `Changes`, `CLAUDE.md`, `.claude/skills/www-authentik-core/SKILL.md`, `t/00-load.t`

**Interfaces:**
- Consumes: die ganze Dist.
- Produces: `AuthentikExecutor->new( base_url =>, flow => $slug )` mit
  `->start`, `->submit( \%answer )`, `->component`, `->challenge`, `->ua`,
  `->login( username =>, password =>, totp_secret => )` → 1 oder Tod mit der Meldung des
  Executors, `->enroll_totp` → das Base32-Geheimnis, `->authorization_code( %param )` → der
  Code aus der 302, `->totp($secret)` → der aktuelle Code.

- [ ] **Step 1: `t/lib/AuthentikExecutor.pm` schreiben**

Kein Teil der öffentlichen API (Spec 11, Punkt 7). Eine eigene `LWP::UserAgent`-Instanz mit
`cookie_jar` und `max_redirect => 0`. Der Ablauf ist Spec 8.3:

- `start`: `GET <base>/api/v3/flows/executor/<flow>/?query=` mit `Accept: application/json`.
- `submit( \%answer )`: `POST` auf dieselbe Adresse mit JSON, Header `X-authentik-CSRF` aus
  dem Cookie `authentik_csrf`. Eine Antwort 302 heißt „nächste Stage“: danach wird `GET`
  wiederholt, bis eine 200 kommt (höchstens fünfmal, dann Tod).
- `login`: `ak-stage-identification` mit `uid_field`, dann `ak-stage-password` mit
  `password`, dann, wenn `ak-stage-authenticator-validate` kommt und ein Geheimnis da ist,
  `code` plus `selected_challenge` aus `device_challenges[0]`. `ak-stage-access-denied`
  bricht mit `error_message` ab (das ist die Antwort bei erzwungenem TOTP ohne Gerät).
  Am Ende `xak-flow-redirect`.
- `enroll_totp`: derselbe Ablauf gegen `default-authenticator-totp-setup`, das Geheimnis aus
  dem `config_url` (`secret=`), dann `code` aus dem Geheimnis zurück.
- `authorization_code`: `GET <base>/application/o/authorize/?…` mit den Cookies, der Code
  kommt aus dem `Location`.
- `totp`: RFC 6238, HMAC-SHA1, sechs Stellen, 30 Sekunden, Base32-Geheimnis
  (`MIME::Base32` ist keine Kernabhängigkeit — das Dekodieren steht als zehn Zeilen im Modul).

- [ ] **Step 2: `t/90-live-authentik.t` schreiben**

```perl
BEGIN {
  plan skip_all => 'set AUTHENTIK_LIVE_TEST=1, AUTHENTIK_URL and AUTHENTIK_TOKEN to run the authentik live test'
    unless $ENV{AUTHENTIK_LIVE_TEST} && $ENV{AUTHENTIK_URL} && $ENV{AUTHENTIK_TOKEN};
}
```

Ein Präfix `wwwak-live-<8 zufällige Buchstaben>` vor jedem Namen und Slug. Ein `END`-Block
räumt in umgekehrter Reihenfolge auf (Bindung, Stage, Flow, Application, Provider, Mapping,
Token, Nutzer, Gruppe) und schluckt dabei jeden Fehler.

Hilfsfunktion:

```perl
sub twice {
  my ( $name, $code ) = @_;
  my $first  = $code->();
  my $second = $code->();
  is( $first->{changed}, 'created', $name.': created' );
  is( $second->{changed}, '', $name.': second run changes nothing' );
  return $first;
}
```

Subtests:

1. `instance` — `version` nennt die Version per `diag`, `me` liefert den Admin.
2. `objects, twice` — `twice` für Gruppe, Nutzer (mit `password` und `group_names`),
   Scope-Mapping, Provider (mit `scopes`, `grant_types`, `redirect_uris` ohne
   `redirect_uri_type`, `authorization_flow` und `invalidation_flow` als Slug,
   `signing_key_name`), Application (mit `provider_name`), Flow, Stage, Bindung, Token.
   Danach je ein geänderter Schlüssel → `updated`, und die nicht genannten Felder stehen noch.
   `ensure_oauth2_provider` ohne `grant_types` wirft.
3. `OIDC` — `discovery`, `issuer`, `jwks`; `client_credentials_token` mit dem Secret des
   Providers, `verify_token( type => 'access' )` und `type => 'id'`; `userinfo`;
   `introspect` (`active` wahr); `revoke`, danach `introspect` falsch und `userinfo` wirft
   mit 401; `device_authorization` und `device_token` bis `authorization_pending`.
4. `a login and the second factor` — der Executor meldet den Nutzer mit Passwort an,
   holt über `authorization_code` einen Code, tauscht ihn mit
   `exchange_authorization_code` und prüft `amr` gleich `['pwd']` sowie `auth_time`;
   dann `enroll_totp`, ein zweiter Login mit dem Code, und `amr` gleich `['pwd','mfa']`.
   `refresh_token` behält `amr` und `auth_time`.
5. `clean up` — alles gelöscht, ein `find_*` liefert nichts mehr.

- [ ] **Step 3: Gegen die Wegwerf-Instanz laufen lassen**

Run: `AUTHENTIK_LIVE_TEST=1 AUTHENTIK_URL=http://127.0.0.1:9000 AUTHENTIK_TOKEN=<Bootstrap-Token> prove -lv t/90-live-authentik.t`
Expected: PASS, fünf Subtests, `diag` nennt `2026.8.3`. Die Suite läuft zweimal
hintereinander grün (sie hängt nicht an den Objekten des ersten Laufs).

- [ ] **Step 4: `README.md`, `Changes`, `CLAUDE.md`, die Kern-Skill und `t/00-load.t` nachziehen**

- `README.md`: Synopsis, Beschreibung, je ein Beispiel für `oidc`, die Grundoperationen und
  `ensure_*`, der Abschnitt zu den Live-Tests mit dem Compose-File, die Lizenz.
- `Changes`: ein Eintrag je Bereich unter `{{$NEXT}}`, kein „Initial skeleton“ mehr.
- `CLAUDE.md` und `.claude/skills/www-authentik-core/SKILL.md`: „Skeleton state“ raus, die
  gebaute Modulkarte rein, Spec und Plan verlinkt.
- `t/00-load.t`: alle neun Module.

- [ ] **Step 5: Alles laufen lassen, committen**

Run: `prove -lr t && dzil test --all` — Expected: beide PASS.
Commit: Betreff `Add the live suite and bring the docs to the built state`.

---

## Selbstprüfung gegen die Spec

- **5.1 Grundoperationen** → Aufgabe 4, Methodentabelle; jede Zeile der Spec-Tabelle kommt vor.
- **5.2 `ensure_*`** → Aufgabe 5, mit allen fünf Regeln (nur Genanntes, erst vergleichen, Listen als Mengen, Defaults, Passwort nur beim Anlegen, nichts löschen).
- **5.3 Was anders zurückkommt** → `Diff` (Aufgabe 1) und `FakeAuthentik` (Aufgabe 2).
- **6 OIDC** → Aufgabe 3, alle Methoden der Spec-Tabelle; kein `password_token`, wie die Spec sagt.
- **6.1 Issuer und Tokenart** → `issuer` aus dem Discovery-Dokument, `type` als Heuristik.
- **6.2 Zweiter Faktor** → Aufgabe 6, Subtest 4, mit erzwungenem TOTP im Executor-Hilfsmodul.
- **7 Fehler** → Aufgabe 2, alle vier Formen, `field_errors`, kein `is_conflict`.
- **8 Beobachtetes** → `FakeAuthentik` antwortet so; die Live-Suite prüft es am echten System.
- **9 Zwilling** → `build_request`/`read_response` getrennt (Aufgabe 2), `_paged` und
  `resolve` als eigene Methoden (Aufgaben 4 und 5), damit der Zwilling sie asynchron nachbaut.
- **10 Tests und Phasen** → Aufgaben 1 bis 6; Phase 2 und 3 sind nicht Teil dieses Plans.
- **11 Entscheidungen** → `api` als Subclient (Aufgabe 4), keine `Auth`-Klasse (Aufgabe 3),
  `grant_types` Pflicht (Aufgabe 5), Auflösung je Feld (Aufgabe 5), Executor in `t/lib`
  (Aufgabe 6), Compose-File schon vorhanden.
- **12 Review** → Rückgabeform in der POD der Fassade (Aufgabe 3), Auflösung ohne Raten
  (Aufgabe 5, Review Focus 1), `type` als Heuristik (Aufgabe 3), erzwungenes TOTP vor dem
  Bau beobachtet und in 6.2 und 8.3 nachgetragen.
