# WWW::Keycloak Phase 1 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** `WWW::Keycloak` Phase 1 bauen: Fassade, Fehler, Admin-Anmeldung mit Token-Erneuerung, die Admin-REST-API mit wiederholbaren `ensure_*`-Methoden, OIDC, Unit-Tests gegen ein nachgebautes Keycloak und eine Live-Suite gegen ein echtes.

**Architecture:** Moo-Klassen nach dem Muster von `WWW::Zitadel`. `WWW::Keycloak` ist die Fassade für einen Realm und baut `WWW::Keycloak::OIDC`, `WWW::Keycloak::Admin` und `WWW::Keycloak::Auth` mit einer gemeinsamen `LWP::UserAgent`. Das Senden und das Abbilden von Keycloaks Fehlerformen liegt in der Rolle `WWW::Keycloak::Role::HTTP`. Der Vergleich hinter `ensure_*` ist eine reine Funktion ohne I/O (`WWW::Keycloak::Diff`), damit der Async-Zwilling sie mitbenutzt.

**Tech Stack:** Perl 5.20+, Moo, Types::Standard, LWP::UserAgent, HTTP::Message, JSON::MaybeXS, Crypt::JWT, URI. Dist::Zilla mit `[@Author::GETTY]`.

**Spec:** `docs/superpowers/specs/2026-10-02-www-keycloak-design.md` (freigegeben 2026-10-03).

## Ausführung

Ausgeführt am 2026-10-03, ein Commit pro Aufgabe (`02e89b1` bis `2023833`). Danach hat ein
unabhängiger Review mit Proben gegen das echte Keycloak Fehler gefunden, die in einem eigenen
Commit behoben sind (Spec-Abschnitt 12); der Code im Repo weicht dort von den Listings unten
ab. Maßgeblich ist das Repo.

## Stand des Codes in diesem Plan

Der gesamte Code ist am 2026-10-03 als Prototyp gelaufen: `prove -lr t` mit 53 Tests grün, `dzil test` im Endzustand grün, und `t/90-live-keycloak.t` grün gegen Keycloak 26.8.0 (Namespace `airlock-test` auf `cihq`). Der Live-Lauf hat zwei Eigenheiten aufgedeckt, die im Code berücksichtigt sind und die niemand „vereinfachen“ darf:

- Keycloak schreibt Nutzernamen und E-Mail-Adressen klein. `ensure_user` vergleicht deshalb klein.
- Keycloak liefert die Werte einer Authenticator-Konfiguration beim Lesen als `**********`. `ensure_execution_config` kann sie weder vergleichen noch zusammenführen; es ersetzt die Konfiguration durch die übergebene und meldet bei jedem Lauf `updated`. Ein Zusammenführen würde die Sternchen als Werte zurückschreiben.

## Global Constraints

- Laufzeit-Abhängigkeiten genau die im `cpanfile` aus Aufgabe 1.
- Ein Paket pro Datei, jede Datei unter `lib/` mit `# ABSTRACT:` und `our $VERSION = '0.001';`.
- Kein `require` zum verzögerten Laden unter `lib/`.
- Jeder Fehler ist ein Objekt aus `WWW::Keycloak::Error::*`, geworfen mit `->throw`. Passwörter und Client-Secrets erscheinen in keiner Fehlermeldung.
- Der Realm ist Teil der Adresse: Pflichtattribut der Fassade, kein Methodenparameter.
- `ensure_*` vergleicht nur die übergebenen Schlüssel, schreibt nur bei Abweichung, löscht nie etwas und liefert `{ id, changed }` mit `changed` gleich `created`, `updated` oder leer.
- Keycloak-Verhalten wird nicht aus dem Gedächtnis kodiert: Was das nachgebaute Keycloak in `t/lib/FakeKeycloak.pm` tut, ist das in Spec-Abschnitt 8 beobachtete.
- Jede `.t`-Datei beginnt mit `#!/usr/bin/env perl`, `use strict; use warnings; use Test::More;` und endet mit `done_testing;`. Tests laufen mit `prove -lr t`.
- Die Live-Suite läuft nur mit `KEYCLOAK_LIVE_TEST=1` und `KEYCLOAK_URL` und nie in einem parallelen Lauf.
- **Niemand außer `www-keycloak-release-manager` committet.** Jede Aufgabe endet mit einem commit-fertigen Baum und einer Übergabe.

## Review Focus

1. **Ein Keycloak-Neustart mitten in einem Setup-Lauf.** Alle Tokens sind danach ungültig. Erwartet: genau ein neuer Login, dann geht es weiter; mit einem festen Token ein klarer 401. Test `a refused token is renewed once` in `t/50-admin.t` (Aufgabe 3).
2. **Ein Setup, das zweimal läuft.** Erwartet: beim zweiten Mal kein einziger schreibender Aufruf außer bei Flow-Einstellungen. Tests mit `writes` in `t/51-admin-ensure.t` (Aufgabe 4) und `twice` in `t/90-live-keycloak.t` (Aufgabe 5).
3. **Ein Passwort im Setup und ein zweiter Lauf.** Erwartet: Das Passwort wird nicht zurückgesetzt. Test `ensure_user` in `t/51-admin-ensure.t` (Aufgabe 4).
4. **Flow-Einstellungen, die Keycloak maskiert zurückgibt.** Erwartet: niemals `**********` als Wert zurückgeschrieben. Test `ensure_execution_config` in `t/51-admin-ensure.t` (Aufgabe 4).
5. **Ein Token, das nicht von diesem Realm stammt, abgelaufen ist, mit fremdem Schlüssel, mit HMAC oder mit `alg: none` signiert ist.** Erwartet: abgelehnt mit Validation-Fehler; ein Token mit neu rotiertem Schlüssel dagegen angenommen. Tests `verify_token` und `key rotation` in `t/60-oidc.t` (Aufgabe 3).

## Dateien

| Datei | Verantwortung | Aufgabe |
|---|---|---|
| `cpanfile` | Abhängigkeiten | 1 |
| `lib/WWW/Keycloak/Diff.pm` | Vergleich ohne I/O | 1 |
| `lib/WWW/Keycloak/Error.pm`, `Error/Validation.pm`, `Error/Network.pm`, `Error/API.pm` | Fehlerhierarchie | 2 |
| `lib/WWW/Keycloak/Role/HTTP.pm` | Senden, JSON, Fehlerformen | 2 |
| `lib/WWW/Keycloak/Auth.pm` | Admin-Token holen und erneuern | 2 |
| `t/lib/FakeKeycloak.pm` | nachgebautes Keycloak für Unit-Tests | 2 |
| `lib/WWW/Keycloak/OIDC.pm` | OIDC | 3 |
| `lib/WWW/Keycloak/Admin.pm` | Admin-API, Grundoperationen | 3 |
| `lib/WWW/Keycloak.pm` | Fassade (der Stub wird ersetzt) | 3 |
| `lib/WWW/Keycloak/Admin.pm` (Abschnitt `ensure`) | wiederholbare Methoden | 4 |
| `t/90-live-keycloak.t`, `t/keycloak/k8s.yaml`, `README.md` | Live-Suite, Wegwerf-Keycloak, Einstieg | 5 |

Reihenfolge: 1 → 2 → 3 → 4 → 5, jede baut auf der vorigen auf. Zuordnung zum Board: Aufgabe 1 bis 4 → Karten 2, 3 und 4 (2 Fassade und Fehler, 3 OIDC, 4 Admin), Aufgabe 5 → Karte 5.

---

### Task 1: Abhängigkeiten und `WWW::Keycloak::Diff`

**Files:**
- Modify: `cpanfile` (ganz ersetzen)
- Create: `lib/WWW/Keycloak/Diff.pm`
- Test: `t/10-diff.t`
- Modify: `t/00-load.t`

**Interfaces:**
- Produces: `WWW::Keycloak::Diff->changes( \%current, \%wanted )` → HashRef der zu schreibenden Schlüssel (verschachtelte Hashes zusammengeführt), leer wenn nichts zu tun ist; `->merge( \%current, \%wanted )` → tief zusammengeführter Hash; `->same( $a, $b )` → 1/0.

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

- [ ] **Step 2: Den Test schreiben**

`t/10-diff.t`:

```perl
#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;

use JSON::MaybeXS;
use WWW::Keycloak::Diff;

my $diff = 'WWW::Keycloak::Diff';

subtest 'same' => sub {
  ok( $diff->same( 'a', 'a' ), 'equal strings' );
  ok( !$diff->same( 'a', 'b' ), 'different strings' );
  ok( $diff->same( 3600, '3600' ), 'number and string' );
  ok( $diff->same( undef, undef ), 'both undef' );
  ok( !$diff->same( undef, '' ), 'undef is not empty' );
  ok( !$diff->same( 'x', undef ), 'value and undef' );
  for my $true ( \1, JSON::MaybeXS::true, 'true', 1 ) {
    for my $other ( \1, JSON::MaybeXS::true, 'true' ) {
      ok( $diff->same( $true, $other ), 'true in any spelling' );
    }
    ok( !$diff->same( $true, \0 ), 'true is not false' );
  }
  for my $false ( \0, JSON::MaybeXS::false, 'false' ) {
    ok( $diff->same( $false, 0 ), 'false in any spelling' );
  }
  ok( !$diff->same( 'true', 'yes' ), 'a string that only looks boolean' );
  ok( !$diff->same( 1, 2 ), 'numbers stay numbers' );
  ok( $diff->same( [qw( a b )], [qw( a b )] ), 'equal lists' );
  ok( !$diff->same( [qw( a b )], [qw( b a )] ), 'order matters in lists' );
  ok( $diff->same( [ { a => 1, b => 2 } ], [ { b => 2, a => 1 } ] ), 'key order inside does not' );
};

subtest 'changes' => sub {
  my $current = {
    id          => 'uuid',
    clientId    => 'cli',
    enabled     => JSON::MaybeXS::true,
    publicClient => JSON::MaybeXS::false,
    redirectUris => ['https://a/*'],
    attributes  => { 'oauth2.device.authorization.grant.enabled' => 'false', 'pkce.code.challenge.method' => 'S256' }
  };
  is_deeply( $diff->changes( $current, { clientId => 'cli', enabled => \1 } ), {}, 'nothing to do' );
  is_deeply( $diff->changes( $current, { publicClient => \1 } ), { publicClient => \1 }, 'one top-level key' );
  is_deeply(
    $diff->changes( $current, { attributes => { 'oauth2.device.authorization.grant.enabled' => 'true' } } ),
    { attributes => { 'oauth2.device.authorization.grant.enabled' => 'true', 'pkce.code.challenge.method' => 'S256' } },
    'a nested hash comes back merged, the untouched key kept'
  );
  is_deeply( $diff->changes( $current, { attributes => { 'pkce.code.challenge.method' => 'S256' } } ), {}, 'a nested key that already matches' );
  is_deeply( $diff->changes( $current, { redirectUris => [ 'https://a/*', 'https://b/*' ] } ), { redirectUris => [ 'https://a/*', 'https://b/*' ] }, 'a list is replaced' );
  is_deeply( $diff->changes( $current, { description => 'new' } ), { description => 'new' }, 'a key the current state lacks' );
  is_deeply( $diff->changes( {}, { a => { b => 1 } } ), { a => { b => 1 } }, 'nested hash where there was none' );
  is_deeply( $diff->changes( { a => 'scalar' }, { a => { b => 1 } } ), { a => { b => 1 } }, 'a hash where there was a scalar' );
  is_deeply( $diff->changes( undef, { a => 1 } ), { a => 1 }, 'undef current' );
  is_deeply( $current->{attributes}{'oauth2.device.authorization.grant.enabled'}, 'false', 'the current state is not modified' );
};

subtest 'merge' => sub {
  my $merged = $diff->merge( { a => 1, h => { x => 1, y => 2 }, l => [1] }, { b => 2, h => { y => 3, z => 4 }, l => [2] } );
  is_deeply( $merged, { a => 1, b => 2, h => { x => 1, y => 3, z => 4 }, l => [2] }, 'deep for hashes, replacing everything else' );
  is_deeply( $diff->merge( undef, { a => 1 } ), { a => 1 }, 'undef current' );
};

done_testing;
```

- [ ] **Step 3: Test laufen lassen, er muss scheitern**

Run: `prove -lr t/10-diff.t` — Expected: FAIL mit `Can't locate WWW/Keycloak/Diff.pm in @INC`.

- [ ] **Step 4: `lib/WWW/Keycloak/Diff.pm` schreiben**

`lib/WWW/Keycloak/Diff.pm`:

```perl
package WWW::Keycloak::Diff;

# ABSTRACT: Compare a Keycloak representation with the wanted state, without I/O

use strict;
use warnings;
use Scalar::Util qw( blessed );
use JSON::MaybeXS;

our $VERSION = '0.001';

=synopsis

    my $changes = WWW::Keycloak::Diff->changes( $current, { enabled => \1, attributes => { a => 'b' } } );
    return unless %$changes;                        # nothing to do
    my $full = WWW::Keycloak::Diff->merge( $current, $wanted );

=description

The comparison behind every C<ensure_*> method of L<WWW::Keycloak::Admin>,
kept free of I/O so that L<Net::Async::Keycloak> uses the very same code.

Only the keys of the wanted state are looked at. Hashes are compared key by
key, so a wanted C<attributes> hash with one entry checks that entry and leaves
the others alone. Lists are compared as a whole. Booleans compare equal
whatever their spelling: C<\1>, a JSON true, C<"true"> and C<1> are the same
value, and so are C<\0>, a JSON false, C<"false"> and C<0>. Everything else is
compared as a string, so C<3600> and C<"3600"> are equal.

=cut

my $JSON = JSON::MaybeXS->new( canonical => 1, allow_nonref => 1, convert_blessed => 1 );

sub changes {
  my ( $self, $current, $wanted ) = @_;
  $current = {} unless ref $current eq 'HASH';
  my %changes;
  for my $key ( keys %$wanted ) {
    my ( $have, $want ) = ( $current->{$key}, $wanted->{$key} );
    if ( ref $want eq 'HASH' ) {
      my $inner = $self->changes( ref $have eq 'HASH' ? $have : {}, $want );
      $changes{$key} = $self->merge( ref $have eq 'HASH' ? $have : {}, $want ) if %$inner;
      next;
    }
    $changes{$key} = $want unless $self->same( $have, $want );
  }
  return \%changes;
}

=method changes

    my $changes = WWW::Keycloak::Diff->changes( \%current, \%wanted );

The keys that have to be written to turn the current state into the wanted
one, as a hash. A nested hash that differs comes back merged with its current
content, because Keycloak replaces such a hash as a whole. Empty when there is
nothing to do.

=cut

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

=method merge

    my $full = WWW::Keycloak::Diff->merge( \%current, \%wanted );

The current state with the wanted keys laid over it, nested hashes merged key
by key.

=cut

sub same {
  my ( $self, $have, $want ) = @_;
  return 1 if !defined $have && !defined $want;
  return 0 if !defined $have || !defined $want;
  my ( $have_bool, $want_bool ) = ( $self->_bool($have), $self->_bool($want) );
  return $have_bool eq $want_bool ? 1 : 0 if defined $have_bool && defined $want_bool
    && ( $self->_is_bool($have) || $self->_is_bool($want) );
  return $JSON->encode($have) eq $JSON->encode($want) ? 1 : 0 if ref $have || ref $want;
  return "$have" eq "$want" ? 1 : 0;
}

=method same

    WWW::Keycloak::Diff->same( $a, $b )

True when two values are the same in the sense described above.

=cut

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

- [ ] **Step 5: Test laufen lassen**

Run: `prove -lr t/10-diff.t` — Expected: PASS (3 Subtests).

- [ ] **Step 6: Load-Test, Übergabe**

`  WWW::Keycloak::Diff` in die Liste in `t/00-load.t`, `prove -lr t` — Expected: PASS. Commit-fertig lassen. Betreff: `Add WWW::Keycloak::Diff and declare dependencies`; `Changes`: `- WWW::Keycloak::Diff: compare a representation with the wanted state, without I/O`.

---

### Task 2: Fehler, HTTP-Rolle, Admin-Anmeldung und das nachgebaute Keycloak

Spec: Abschnitte 4 und 7.

**Files:**
- Create: `lib/WWW/Keycloak/Error.pm`, `lib/WWW/Keycloak/Error/Validation.pm`, `lib/WWW/Keycloak/Error/Network.pm`, `lib/WWW/Keycloak/Error/API.pm`
- Create: `lib/WWW/Keycloak/Role/HTTP.pm`, `lib/WWW/Keycloak/Auth.pm`
- Create: `t/lib/FakeKeycloak.pm`
- Test: `t/30-auth.t`
- Modify: `t/00-load.t`

**Interfaces:**
- Produces:
  - `WWW::Keycloak::Error::*->throw( message => ..., ... )`; `::API` mit `http_status` (Zahl), `api_message`, `oauth_error`, `is_not_found`, `is_conflict`, `is_unauthorized`.
  - Rolle `WWW::Keycloak::Role::HTTP` (der Konsument hat ein Attribut `ua`): `send_request( $method, $url, json => \%body | form => \%fields, bearer => $token )` → `{ status, data, location }`; wirft `::Network` ohne Antwort, `::API` ab Status 400.
  - `WWW::Keycloak::Auth->new( ua =>, token_endpoint =>, username => + password => | client_id => + client_secret => | token =>, margin => 30, now => sub )`; `->token`, `->invalidate`, `->renewable`.
  - Test-Fixture `FakeKeycloak->new( expires_in => $s )`: eine Unterklasse von `LWP::UserAgent`, die Keycloak im Speicher spielt; `->base`, `->logins`, `->requests`, `->realm($name)`, `->add_realm($name)`, `->forget_tokens`, `->rotate_key`, `->sign( \%claims, alg =>, key =>, kid => )`. Admin-Zugang: Nutzer `admin`, Passwort `admin`; Service-Account-Secret `secret`.

- [ ] **Step 1: Das nachgebaute Keycloak schreiben**

Es antwortet so, wie das echte am 2026-10-02 und 2026-10-03 beobachtet wurde (Spec-Abschnitt 8), einschließlich der maskierten Flow-Einstellungen.

`t/lib/FakeKeycloak.pm`:

```perl
package FakeKeycloak;

# An in-memory stand-in for the parts of Keycloak 26 that WWW::Keycloak talks
# to, answering the way the real one was observed to answer: 201 with a
# Location header and no body when something is created, 409 with
# errorMessage for a duplicate, 404 with error for something missing, 401
# for a token it does not know, masked values when an authenticator
# configuration is read.
#
#   my $fake = FakeKeycloak->new;
#   my $kc   = WWW::Keycloak->new( base_url => $fake->base, realm => 'r', username => 'admin', password => 'admin', ua => $fake );

use strict;
use warnings;
use parent 'LWP::UserAgent';
use Crypt::JWT qw( encode_jwt );
use Crypt::PK::RSA;
use HTTP::Response;
use JSON::MaybeXS;
use URI;
use URI::Escape ();

my $JSON = JSON::MaybeXS->new( utf8 => 1, canonical => 1 );

sub new {
  my ( $class, %arg ) = @_;
  my $self = $class->SUPER::new;
  my $key  = Crypt::PK::RSA->new;
  $key->generate_key( 256, 65537 );
  %$self = (
    %$self,
    base       => 'http://kc.test',
    now        => $arg{now} || sub { time },
    expires_in => $arg{expires_in} // 300,
    key        => $key,
    kid        => 'key-1',
    tokens     => {},
    logins     => [],
    requests   => [],
    seq        => 0,
    realms     => {}
  );
  $self->add_realm('master');
  return $self;
}

sub base     { $_[0]{base} }
sub logins   { $_[0]{logins} }
sub requests { $_[0]{requests} }
sub realm    { $_[0]{realms}{ $_[1] } }

# what a Keycloak restart does to the admin tokens it handed out
sub forget_tokens { $_[0]{tokens} = {} }

sub rotate_key {
  my ( $self ) = @_;
  my $key = Crypt::PK::RSA->new;
  $key->generate_key( 256, 65537 );
  $self->{key} = $key;
  $self->{kid} = 'key-'.++$self->{seq};
  return;
}

sub add_realm {
  my ( $self, $name, %rep ) = @_;
  $self->{realms}{$name} = {
    rep     => { realm => $name, enabled => JSON::MaybeXS::true, accessTokenLifespan => 300, %rep },
    clients => {},
    scopes  => {},
    users   => {},
    mappers => {},
    configs => {},
    flows   => {
      'browser' => [
        { id => 'e-cookie', providerId => 'auth-cookie', level => 0 },
        { id => 'e-forms', displayName => 'forms', level => 0 },
        { id => 'e-pwd', providerId => 'auth-username-password-form', level => 1 },
        { id => 'e-otp', providerId => 'auth-otp-form', level => 2 }
      ],
      'direct grant' => [
        { id => 'e-dg-pwd', providerId => 'direct-grant-validate-password', level => 0 },
        { id => 'e-dg-otp', providerId => 'direct-grant-validate-otp', level => 1 }
      ]
    }
  };
  return;
}

sub sign {
  my ( $self, $claims, %opt ) = @_;
  return encode_jwt( payload => $claims, alg => $opt{alg} // 'RS256', key => $opt{key} // $self->{key}, extra_headers => { kid => $opt{kid} // $self->{kid} } );
}

sub _id { 'id-'.++$_[0]{seq} }

sub _reply {
  my ( $self, $status, $data, %header ) = @_;
  my $response = HTTP::Response->new( $status, $status < 300 ? 'OK' : 'Error' );
  $response->header( %header ) if %header;
  if ( defined $data ) {
    $response->header( 'Content-Type' => 'application/json' );
    $response->content( $JSON->encode($data) );
  }
  return $response;
}

sub request {
  my ( $self, $request ) = @_;
  push @{ $self->{requests} }, $request;
  my $uri  = URI->new( $request->uri );
  my $path = $uri->path;
  my %query = $uri->query_form;
  my $body;
  if ( length( $request->content // '' ) ) {
    $body = ( $request->header('Content-Type') // '' ) =~ /json/ ? $JSON->decode( $request->content ) : { URI->new( 'http:?'.$request->content )->query_form };
  }
  my $method = $request->method;

  if ( $path =~ m{\A/realms/([^/]+)/(.*)\z} ) {
    my ( $realm, $rest ) = ( $1, $2 );
    return $self->_reply( 404, { error => 'Realm does not exist' } ) unless $self->{realms}{$realm};
    return $self->_oidc( $realm, $rest, $method, $body, $request );
  }
  return $self->_reply( 404, { error => 'not found' } ) unless $path =~ m{\A/admin/(.*)\z};
  my $admin = $1;
  my ( $bearer ) = ( $request->header('Authorization') // '' ) =~ /\ABearer (.+)\z/;
  return $self->_reply( 401, { error => 'HTTP 401 Unauthorized' } ) unless $bearer && $self->{tokens}{$bearer};

  return $self->_reply( 200, { systemInfo => { version => '26.8.0' } } ) if $admin eq 'serverinfo';
  if ( $admin eq 'realms' && $method eq 'POST' ) {
    return $self->_reply( 409, { errorMessage => 'Realm '.$body->{realm}.' already exists' } ) if $self->{realms}{ $body->{realm} };
    $self->add_realm( $body->{realm}, %$body );
    return $self->_reply( 201, undef, Location => $self->{base}.'/admin/realms/'.$body->{realm} );
  }
  $admin =~ m{\Arealms/([^/]+)(.*)\z} or return $self->_reply( 404, { error => 'not found' } );
  my ( $name, $rest ) = ( URI::Escape::uri_unescape($1), $2 );
  my $realm = $self->{realms}{$name} or return $self->_reply( 404, { error => 'Realm not found.' } );
  return $self->_admin( $name, $realm, $rest, $method, $body, \%query );
}

sub _oidc {
  my ( $self, $realm, $rest, $method, $body, $request ) = @_;
  my $issuer = $self->{base}.'/realms/'.$realm;
  if ( $rest eq '.well-known/openid-configuration' ) {
    return $self->_reply( 200, {
      issuer                        => $issuer,
      token_endpoint                => $issuer.'/protocol/openid-connect/token',
      userinfo_endpoint             => $issuer.'/protocol/openid-connect/userinfo',
      introspection_endpoint        => $issuer.'/protocol/openid-connect/token/introspect',
      end_session_endpoint          => $issuer.'/protocol/openid-connect/logout',
      device_authorization_endpoint => $issuer.'/protocol/openid-connect/auth/device',
      jwks_uri                      => $issuer.'/protocol/openid-connect/certs'
    } );
  }
  if ( $rest eq 'protocol/openid-connect/certs' ) {
    return $self->_reply( 200, { keys => [ { %{ $self->{key}->export_key_jwk( 'public', 1 ) }, kid => $self->{kid}, use => 'sig', alg => 'RS256' } ] } );
  }
  if ( $rest eq 'protocol/openid-connect/token' ) {
    push @{ $self->{logins} }, { realm => $realm, %$body };
    my $grant = $body->{grant_type} // '';
    if ( $grant eq 'password' ) {
      return $self->_reply( 401, { error => 'invalid_grant', error_description => 'Invalid user credentials' } )
        unless ( $body->{username} // '' ) eq 'admin' && ( $body->{password} // '' ) eq 'admin';
    }
    elsif ( $grant eq 'client_credentials' ) {
      return $self->_reply( 401, { error => 'unauthorized_client', error_description => 'Invalid client or Invalid client credentials' } )
        unless ( $body->{client_secret} // '' ) eq 'secret';
    }
    elsif ( $grant eq 'refresh_token' ) {
      return $self->_reply( 400, { error => 'invalid_grant', error_description => 'Invalid refresh token' } )
        unless $body->{refresh_token} && $self->{tokens}{ 'refresh:'.$body->{refresh_token} };
    }
    elsif ( $grant eq 'urn:ietf:params:oauth:grant-type:device_code' ) {
      return $self->_reply( 400, { error => 'authorization_pending', error_description => 'The authorization request is still pending' } );
    }
    else {
      return $self->_reply( 400, { error => 'unsupported_grant_type', error_description => 'Unsupported grant_type' } );
    }
    my $access  = 'at-'.$self->_id;
    my $refresh = 'rt-'.$self->_id;
    $self->{tokens}{$access} = 1;
    $self->{tokens}{ 'refresh:'.$refresh } = 1;
    return $self->_reply( 200, { access_token => $access, expires_in => $self->{expires_in}, refresh_token => $refresh, refresh_expires_in => 1800, token_type => 'Bearer' } );
  }
  if ( $rest eq 'protocol/openid-connect/auth/device' ) {
    return $self->_reply( 200, { device_code => 'dc', user_code => 'ABCD-EFGH', verification_uri => $issuer.'/device', verification_uri_complete => $issuer.'/device?user_code=ABCD-EFGH', expires_in => 600, interval => 5 } );
  }
  if ( $rest eq 'protocol/openid-connect/userinfo' ) {
    my ( $bearer ) = ( $request->header('Authorization') // '' ) =~ /\ABearer (.+)\z/;
    return $self->_reply( 401, { error => 'invalid_token' } ) unless ( $bearer // '' ) eq 'user-token';
    return $self->_reply( 200, { sub => 'u-1', preferred_username => 'alice' } );
  }
  if ( $rest eq 'protocol/openid-connect/token/introspect' ) {
    return $self->_reply( 200, { active => ( $body->{token} // '' ) eq 'user-token' ? JSON::MaybeXS::true : JSON::MaybeXS::false } );
  }
  if ( $rest eq 'protocol/openid-connect/logout' ) {
    return $self->_reply( 204 );
  }
  return $self->_reply( 404, { error => 'not found' } );
}

sub _admin {
  my ( $self, $name, $realm, $rest, $method, $body, $query ) = @_;
  my $created = sub { $self->_reply( 201, undef, Location => $self->{base}.'/admin/realms/'.$name.$_[0] ) };

  if ( $rest eq '' ) {
    return $self->_reply( 200, { %{ $realm->{rep} } } ) if $method eq 'GET';
    if ( $method eq 'PUT' ) { %{ $realm->{rep} } = ( %{ $realm->{rep} }, %$body ); return $self->_reply(204) }
    if ( $method eq 'DELETE' ) { delete $self->{realms}{$name}; return $self->_reply(204) }
  }

  # clients
  if ( $rest eq '/clients' ) {
    if ( $method eq 'GET' ) {
      return $self->_reply( 200, [ grep { !defined $query->{clientId} || $_->{clientId} eq $query->{clientId} } map { { %$_ } } sort { $a->{id} cmp $b->{id} } values %{ $realm->{clients} } ] );
    }
    return $self->_reply( 409, { errorMessage => 'Client '.$body->{clientId}.' already exists' } )
      if grep { $_->{clientId} eq $body->{clientId} } values %{ $realm->{clients} };
    my $id = $self->_id;
    $realm->{clients}{$id} = { publicClient => JSON::MaybeXS::false, enabled => JSON::MaybeXS::true, attributes => {}, %$body, id => $id };
    return $created->( '/clients/'.$id );
  }
  if ( $rest =~ m{\A/clients/([^/]+)(.*)\z} ) {
    my ( $id, $sub ) = ( $1, $2 );
    my $client = $realm->{clients}{$id} or return $self->_reply( 404, { error => 'Could not find client' } );
    if ( $sub eq '' ) {
      return $self->_reply( 200, { %$client } ) if $method eq 'GET';
      if ( $method eq 'PUT' ) { $realm->{clients}{$id} = { %$body, id => $id }; return $self->_reply(204) }
      if ( $method eq 'DELETE' ) { delete $realm->{clients}{$id}; return $self->_reply(204) }
    }
    return $self->_reply( 200, { type => 'secret', value => 'client-secret-'.$id } ) if $sub eq '/client-secret';
    return $self->_reply( 200, { username => 'service-account-'.$client->{clientId} } ) if $sub eq '/service-account-user';
    if ( $sub =~ m{\A/default-client-scopes/(.+)\z} ) { push @{ $client->{defaultClientScopes} }, $1; return $self->_reply(204) }
    return $self->_mappers( $name, 'clients', $id, $sub, $method, $body ) if $sub =~ m{\A/protocol-mappers/models};
  }

  # client scopes
  if ( $rest eq '/client-scopes' ) {
    return $self->_reply( 200, [ map { { %$_ } } sort { $a->{id} cmp $b->{id} } values %{ $realm->{scopes} } ] ) if $method eq 'GET';
    return $self->_reply( 409, { errorMessage => 'Client Scope '.$body->{name}.' already exists' } )
      if grep { $_->{name} eq $body->{name} } values %{ $realm->{scopes} };
    my $id = $self->_id;
    $realm->{scopes}{$id} = { %$body, id => $id };
    return $created->( '/client-scopes/'.$id );
  }
  if ( $rest =~ m{\A/client-scopes/([^/]+)(.*)\z} ) {
    my ( $id, $sub ) = ( $1, $2 );
    my $scope = $realm->{scopes}{$id} or return $self->_reply( 404, { error => 'Could not find client scope' } );
    if ( $sub eq '' ) {
      return $self->_reply( 200, { %$scope } ) if $method eq 'GET';
      if ( $method eq 'PUT' ) { $realm->{scopes}{$id} = { %$body, id => $id }; return $self->_reply(204) }
      if ( $method eq 'DELETE' ) { delete $realm->{scopes}{$id}; return $self->_reply(204) }
    }
    return $self->_mappers( $name, 'client-scopes', $id, $sub, $method, $body ) if $sub =~ m{\A/protocol-mappers/models};
  }
  if ( $rest =~ m{\A/default-default-client-scopes/(.+)\z} ) { push @{ $realm->{rep}{defaultDefaultClientScopes} }, $1; return $self->_reply(204) }

  # users
  if ( $rest eq '/users' ) {
    if ( $method eq 'GET' ) {
      return $self->_reply( 200, [ grep { !defined $query->{username} || $_->{username} eq lc $query->{username} } map { my %u = %$_; delete $u{credentials}; \%u } sort { $a->{id} cmp $b->{id} } values %{ $realm->{users} } ] );
    }
    my $username = lc $body->{username};
    return $self->_reply( 409, { errorMessage => 'User exists with same username' } )
      if grep { $_->{username} eq $username } values %{ $realm->{users} };
    my $id = $self->_id;
    $realm->{users}{$id} = { enabled => JSON::MaybeXS::false, %$body, username => $username, defined $body->{email} ? ( email => lc $body->{email} ) : (), id => $id, credentials => [ map { { %$_, id => $self->_id } } @{ $body->{credentials} || [] } ] };
    return $created->( '/users/'.$id );
  }
  if ( $rest =~ m{\A/users/([^/]+)(.*)\z} ) {
    my ( $id, $sub ) = ( $1, $2 );
    my $user = $realm->{users}{$id} or return $self->_reply( 404, { error => 'User not found' } );
    if ( $sub eq '' ) {
      if ( $method eq 'GET' ) { my %u = %$user; delete $u{credentials}; return $self->_reply( 200, \%u ) }
      if ( $method eq 'PUT' ) { my %b = %$body; delete $b{credentials}; %$user = ( %$user, %b, id => $id ); return $self->_reply(204) }
      if ( $method eq 'DELETE' ) { delete $realm->{users}{$id}; return $self->_reply(204) }
    }
    if ( $sub eq '/reset-password' ) {
      $user->{credentials} = [ ( grep { $_->{type} ne 'password' } @{ $user->{credentials} } ), { %$body, id => $self->_id } ];
      return $self->_reply(204);
    }
    return $self->_reply( 200, [ map { { id => $_->{id}, type => $_->{type} } } @{ $user->{credentials} } ] ) if $sub eq '/credentials';
    if ( $sub =~ m{\A/credentials/(.+)\z} ) { my $cid = $1; $user->{credentials} = [ grep { $_->{id} ne $cid } @{ $user->{credentials} } ]; return $self->_reply(204) }
    return $self->_reply( 200, [] ) if $sub eq '/sessions';
    return $self->_reply(204) if $sub eq '/logout';
  }

  # authentication
  return $self->_reply( 200, [ map { { alias => $_, builtIn => JSON::MaybeXS::true } } sort keys %{ $realm->{flows} } ] ) if $rest eq '/authentication/flows';
  if ( $rest =~ m{\A/authentication/flows/([^/]+)/(executions|copy)\z} ) {
    my ( $alias, $what ) = ( URI::Escape::uri_unescape($1), $2 );
    my $flow = $realm->{flows}{$alias} or return $self->_reply( 404, { error => 'Flow not found' } );
    return $self->_reply( 200, [ map { { %$_ } } @$flow ] ) if $what eq 'executions';
    $realm->{flows}{ $body->{newName} } = [ map { { %$_, id => $_->{id}.'-copy' } } @$flow ];
    return $created->( '/authentication/flows/'.$alias.'/copy/'.$self->_id );
  }
  if ( $rest =~ m{\A/authentication/executions/([^/]+)/config\z} ) {
    my $execution_id = $1;
    my ( $execution ) = grep { $_->{id} eq $execution_id } map { @$_ } values %{ $realm->{flows} };
    return $self->_reply( 404, { error => 'Illegal execution' } ) unless $execution;
    my $id = $self->_id;
    $realm->{configs}{$id} = { %$body, id => $id };
    $execution->{authenticationConfig} = $id;
    return $created->( '/authentication/config/'.$id );
  }
  if ( $rest =~ m{\A/authentication/config/([^/]+)\z} ) {
    my $config = $realm->{configs}{$1} or return $self->_reply( 404, { error => 'Could not find authenticator config' } );
    return $self->_reply( 200, { %$config, config => { map { $_ => '**********' } keys %{ $config->{config} } } } ) if $method eq 'GET';
    %$config = ( %$body, id => $config->{id} );
    return $self->_reply(204);
  }
  return $self->_reply( 200, { properties => [] } ) if $rest =~ m{\A/authentication/config-description/};
  if ( $rest =~ m{\A/partial-export} ) { return $self->_reply( 200, { realm => $name, clients => [ values %{ $realm->{clients} } ] } ) }
  if ( $rest eq '/partialImport' ) {
    my $added = 0;
    for my $user ( @{ $body->{users} || [] } ) { my $id = $self->_id; $realm->{users}{$id} = { %$user, username => lc $user->{username}, id => $id }; $added++ }
    return $self->_reply( 200, { added => $added, skipped => 0, overwritten => 0 } );
  }
  return $self->_reply( 404, { error => 'not found: '.$method.' '.$rest } );
}

sub _mappers {
  my ( $self, $name, $kind, $owner, $sub, $method, $body ) = @_;
  my $realm   = $self->{realms}{$name};
  my $mappers = $realm->{mappers}{ $kind.'/'.$owner } ||= {};
  if ( $sub eq '/protocol-mappers/models' ) {
    return $self->_reply( 200, [ map { { %$_ } } sort { $a->{id} cmp $b->{id} } values %$mappers ] ) if $method eq 'GET';
    return $self->_reply( 409, { errorMessage => 'Protocol mapper exists with same name' } ) if grep { $_->{name} eq $body->{name} } values %$mappers;
    my $id = $self->_id;
    $mappers->{$id} = { config => {}, %$body, id => $id };
    return $self->_reply( 201, undef, Location => $self->{base}.'/admin/realms/'.$name.'/'.$kind.'/'.$owner.'/protocol-mappers/models/'.$id );
  }
  $sub =~ m{\A/protocol-mappers/models/(.+)\z} or return $self->_reply( 404, { error => 'not found' } );
  my $mapper = $mappers->{$1} or return $self->_reply( 404, { error => 'Model not found' } );
  if ( $method eq 'PUT' ) { %$mapper = ( %$body, id => $mapper->{id} ); return $self->_reply(204) }
  if ( $method eq 'DELETE' ) { delete $mappers->{ $mapper->{id} }; return $self->_reply(204) }
  return $self->_reply( 200, { %$mapper } );
}

1;
```

- [ ] **Step 2: Den Test schreiben**

`t/30-auth.t`:

```perl
#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use lib 't/lib';

use FakeKeycloak;
use WWW::Keycloak::Auth;

my $clock = 1_000_000;
my $fake  = FakeKeycloak->new( expires_in => 60 );

sub auth {
  return WWW::Keycloak::Auth->new( ua => $fake, token_endpoint => $fake->base.'/realms/master/protocol/openid-connect/token', now => sub { $clock }, @_ );
}

subtest 'password login, kept, renewed' => sub {
  @{ $fake->logins } = ();
  my $auth  = auth( username => 'admin', password => 'admin' );
  my $first = $auth->token;
  like( $first, qr/\Aat-/, 'a token' );
  is( $fake->logins->[0]{grant_type}, 'password', 'by password grant' );
  is( $fake->logins->[0]{client_id}, 'admin-cli', 'through admin-cli' );
  $clock += 29;
  is( $auth->token, $first, 'kept while more than the margin is left' );
  is( scalar @{ $fake->logins }, 1, 'without asking again' );
  $clock += 1;
  my $second = $auth->token;
  isnt( $second, $first, 'renewed 30 seconds before expiry' );
  is( $fake->logins->[1]{grant_type}, 'refresh_token', 'with the refresh token' );
};

subtest 'refresh refused: log in again' => sub {
  @{ $fake->logins } = ();
  my $auth = auth( username => 'admin', password => 'admin' );
  $auth->token;
  $fake->forget_tokens;
  $clock += 60;
  ok( $auth->token, 'still a token' );
  is_deeply( [ map { $_->{grant_type} } @{ $fake->logins } ], [qw( password refresh_token password )], 'refresh failed, password login followed' );
};

subtest 'invalidate' => sub {
  @{ $fake->logins } = ();
  my $auth  = auth( username => 'admin', password => 'admin' );
  my $first = $auth->token;
  $auth->invalidate;
  isnt( $auth->token, $first, 'a new token after invalidate' );
  is( $fake->logins->[1]{grant_type}, 'password', 'by logging in, not by refresh' );
};

subtest 'service account' => sub {
  @{ $fake->logins } = ();
  my $auth = auth( client_id => 'provisioner', client_secret => 'secret' );
  ok( $auth->token, 'token' );
  is_deeply( [ @{ $fake->logins->[0] }{qw( grant_type client_id client_secret )} ], [qw( client_credentials provisioner secret )], 'client credentials grant' );
};

subtest 'fixed token' => sub {
  my $auth = WWW::Keycloak::Auth->new( ua => $fake, token => 'fixed' );
  is( $auth->token, 'fixed', 'used as it is' );
  is( $auth->renewable, 0, 'and not renewable' );
};

subtest 'refusals' => sub {
  my $wrong = auth( username => 'admin', password => 'guess' );
  ok( !eval { $wrong->token; 1 }, 'wrong password croaks' );
  isa_ok( $@, 'WWW::Keycloak::Error::API' );
  like( "$@", qr/\Aadmin login failed: 401 - invalid_grant/, 'and says so' );
  unlike( "$@", qr/guess/, 'without the password' );

  ok( !eval { auth( client_id => 'x', client_secret => 'leaked-secret' )->token; 1 }, 'wrong secret croaks' );
  unlike( "$@", qr/leaked-secret/, 'without the secret' );

  ok( !eval { WWW::Keycloak::Auth->new( ua => $fake, token_endpoint => 'x' ); 1 }, 'no credentials' );
  isa_ok( $@, 'WWW::Keycloak::Error::Validation' );
  ok( !eval { WWW::Keycloak::Auth->new( ua => $fake, username => 'a', password => 'b' ); 1 }, 'no token endpoint' );
  ok( !eval { WWW::Keycloak::Auth->new( ua => $fake, token_endpoint => 'x', username => 'a' ); 1 }, 'username without password' );
};

done_testing;
```

- [ ] **Step 3: Test laufen lassen, er muss scheitern**

Run: `prove -lr t/30-auth.t` — Expected: FAIL mit `Can't locate WWW/Keycloak/Auth.pm in @INC`.

- [ ] **Step 4: Die Fehlerklassen schreiben**

`lib/WWW/Keycloak/Error.pm`:

```perl
package WWW::Keycloak::Error;

# ABSTRACT: Exception base class for WWW::Keycloak

use Moo;

# No namespace::autoclean here: it would remove the overload stub.
use overload '""' => sub { $_[0]->message }, fallback => 1;

our $VERSION = '0.001';

=synopsis

    use Scalar::Util qw( blessed );

    my $client = eval { $admin->get_client($id) };
    if ( blessed $@ && $@->isa('WWW::Keycloak::Error::API') && $@->is_not_found ) { ... }

=description

Every error WWW::Keycloak raises is an object of one of three subclasses:
L<WWW::Keycloak::Error::Validation> for wrong arguments,
L<WWW::Keycloak::Error::Network> when no HTTP answer arrived, and
L<WWW::Keycloak::Error::API> when Keycloak answered with an error. All of them
stringify to their message, so plain C<$@> matching keeps working.

=cut

has message => (
  is       => 'ro',
  required => 1
);

=attr message

The human-readable description. The object stringifies to it.

=cut

sub throw {
  my ( $class, %arg ) = @_;
  die $class->new(%arg);
}

=method throw

    WWW::Keycloak::Error::Validation->throw( message => 'realm is required' );

Builds the exception and dies with it.

=cut

1;
```

`lib/WWW/Keycloak/Error/Validation.pm`:

```perl
package WWW::Keycloak::Error::Validation;

# ABSTRACT: Raised for arguments WWW::Keycloak cannot work with

use Moo;
extends 'WWW::Keycloak::Error';

our $VERSION = '0.001';

1;
```

`lib/WWW/Keycloak/Error/Network.pm`:

```perl
package WWW::Keycloak::Error::Network;

# ABSTRACT: Raised when Keycloak could not be reached

use Moo;
extends 'WWW::Keycloak::Error';

our $VERSION = '0.001';

1;
```

`lib/WWW/Keycloak/Error/API.pm`:

```perl
package WWW::Keycloak::Error::API;

# ABSTRACT: Raised when Keycloak answers with an HTTP error

use Moo;
extends 'WWW::Keycloak::Error';

our $VERSION = '0.001';

=description

Keycloak reports errors in three shapes, and all of them end up in
L</api_message>: C<{"errorMessage": "..."}> from most of the Admin API,
C<{"error": "..."}> from some of it, and the OAuth form
C<{"error": "...", "error_description": "..."}> from the token endpoint, where
L</oauth_error> also carries the bare code.

=cut

has http_status => (
  is       => 'ro',
  required => 1
);

=attr http_status

The HTTP status code as a number, for example 409.

=cut

has api_message => ( is => 'ro' );

=attr api_message

What Keycloak said, if it said anything.

=cut

has oauth_error => ( is => 'ro' );

=attr oauth_error

The OAuth error code (C<invalid_grant>, C<authorization_pending>, ...) when
the error came from an OAuth endpoint.

=cut

sub is_not_found    { $_[0]->http_status == 404 ? 1 : 0 }
sub is_conflict     { $_[0]->http_status == 409 ? 1 : 0 }
sub is_unauthorized { $_[0]->http_status == 401 ? 1 : 0 }

=method is_not_found

=method is_conflict

=method is_unauthorized

True for status 404, 409 and 401.

=cut

1;
```

- [ ] **Step 5: Die HTTP-Rolle schreiben**

Die Rolle verlangt `ua` nicht per `requires`, weil die Klassen sie direkt unter `use Moo` einbinden, bevor ihre Attribute existieren.

`lib/WWW/Keycloak/Role/HTTP.pm`:

```perl
package WWW::Keycloak::Role::HTTP;

# ABSTRACT: Sending requests to Keycloak and turning failures into exceptions

use HTTP::Request;
use JSON::MaybeXS;
use URI;
use WWW::Keycloak::Error::API;
use WWW::Keycloak::Error::Network;
use Moo::Role;

our $VERSION = '0.001';

=description

What L<WWW::Keycloak::Admin>, L<WWW::Keycloak::OIDC> and
L<WWW::Keycloak::Auth> share: one L<LWP::UserAgent>, JSON in and out, and the
mapping of Keycloak's three error shapes onto L<WWW::Keycloak::Error::API>.

=cut

sub json_codec { JSON::MaybeXS->new( utf8 => 1, canonical => 1, convert_blessed => 1 ) }

sub send_request {
  my ( $self, $method, $url, %arg ) = @_;
  my $request = HTTP::Request->new( $method => $url );
  $request->header( Accept => 'application/json' );
  $request->header( Authorization => 'Bearer '.$arg{bearer} ) if defined $arg{bearer};
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
  my $response = $self->ua->request($request);
  WWW::Keycloak::Error::Network->throw( message => $method.' '.$url.': '.$response->status_line )
    if $response->code == 500 && ( $response->header('Client-Warning') // '' ) eq 'Internal response';
  my $content = $response->decoded_content // '';
  my $data    = length $content ? eval { $self->json_codec->decode( $response->content ) } : undef;
  return { status => $response->code, data => $data, location => scalar $response->header('Location') }
    if $response->is_success;
  my ( $message, $oauth );
  if ( ref $data eq 'HASH' ) {
    $message = $data->{errorMessage} // $data->{error};
    if ( defined $data->{error} && defined $data->{error_description} || $arg{form} ) {
      $oauth = $data->{error};
      $message = $data->{error}.( defined $data->{error_description} ? ': '.$data->{error_description} : '' )
        if defined $data->{error};
    }
  }
  WWW::Keycloak::Error::API->throw(
    message     => $method.' '.$url.' failed: '.$response->status_line.( defined $message ? ' - '.$message : '' ),
    http_status => $response->code,
    api_message => $message,
    oauth_error => $oauth
  );
}

=method send_request

    my $result = $self->send_request( POST => $url, json => \%body, bearer => $token );
    my $result = $self->send_request( POST => $url, form => \%fields );

Sends one request. Returns C<status>, the decoded C<data> and the C<location>
header. Throws L<WWW::Keycloak::Error::Network> when no answer came back and
L<WWW::Keycloak::Error::API> for any status of 400 and above.

=cut

1;
```

- [ ] **Step 6: `lib/WWW/Keycloak/Auth.pm` schreiben**

`lib/WWW/Keycloak/Auth.pm`:

```perl
package WWW::Keycloak::Auth;

# ABSTRACT: Get and keep a valid admin token for the Keycloak Admin API

use Moo;
with 'WWW::Keycloak::Role::HTTP';
use Types::Standard qw( CodeRef InstanceOf Int Str );
use WWW::Keycloak::Error::Validation;
use namespace::autoclean;

our $VERSION = '0.001';

=synopsis

    my $auth = WWW::Keycloak::Auth->new(
      token_endpoint => 'https://id.example.org/realms/master/protocol/openid-connect/token',
      username       => 'admin',
      password       => $password,
      ua             => $lwp,
    );
    my $bearer = $auth->token;

=description

Keycloak has no long-lived admin tokens. This class logs in when a token is
first needed, keeps it, renews it shortly before it runs out (with the refresh
token while that is valid, otherwise by logging in again), and forgets it when
told the token was refused. Three ways to log in: a username and password
through the C<admin-cli> client, a service-account client with its secret, or
a fixed token that is used as it is and never renewed.

Passwords and secrets never appear in an exception.

=cut

has ua => (
  is       => 'ro',
  isa      => InstanceOf['LWP::UserAgent'],
  required => 1
);

=attr ua

Required. The L<LWP::UserAgent> to use.

=cut

has token_endpoint => (
  is  => 'ro',
  isa => Str
);

=attr token_endpoint

The token endpoint of the realm the admin logs in to. Required unless
C<token> is given.

=cut

has username      => ( is => 'ro', isa => Str, predicate => 'has_username' );
has password      => ( is => 'ro', isa => Str );
has client_id     => ( is => 'ro', isa => Str, predicate => 'has_client_id' );
has client_secret => ( is => 'ro', isa => Str );
has fixed_token   => ( is => 'ro', isa => Str, init_arg => 'token', predicate => 'has_fixed_token' );

=attr username

=attr password

Log in with the password grant through C<admin-cli>, or through C<client_id>
when that is given too.

=attr client_id

=attr client_secret

Log in with the client credentials grant of a service-account client.

=attr token

A ready token. Used as it is; when it runs out, requests fail.

=cut

has margin => (
  is      => 'ro',
  isa     => Int,
  default => 30
);

=attr margin

Seconds before expiry at which a token is renewed. Default 30.

=cut

has now => (
  is      => 'ro',
  isa     => CodeRef,
  default => sub { sub { time } }
);

=attr now

Coderef returning the current epoch. For tests.

=cut

has _access          => ( is => 'rw' );
has _access_expires  => ( is => 'rw' );
has _refresh         => ( is => 'rw' );
has _refresh_expires => ( is => 'rw' );

sub BUILD {
  my ( $self ) = @_;
  return if $self->has_fixed_token;
  WWW::Keycloak::Error::Validation->throw( message => __PACKAGE__.' needs username and password, client_id and client_secret, or token' )
    unless ( $self->has_username && defined $self->password ) || ( $self->has_client_id && defined $self->client_secret );
  WWW::Keycloak::Error::Validation->throw( message => __PACKAGE__.' needs a token_endpoint' )
    unless defined $self->token_endpoint && length $self->token_endpoint;
  return;
}

sub renewable { $_[0]->has_fixed_token ? 0 : 1 }

=method renewable

False for a fixed token, which this class cannot replace.

=cut

sub token {
  my ( $self ) = @_;
  return $self->fixed_token if $self->has_fixed_token;
  my $now = $self->now->();
  return $self->_access if defined $self->_access && $now < $self->_access_expires - $self->margin;
  if ( defined $self->_refresh && $now < $self->_refresh_expires - $self->margin ) {
    my $renewed = eval {
      $self->_grant( { grant_type => 'refresh_token', refresh_token => $self->_refresh, $self->_client } );
      1;
    };
    return $self->_access if $renewed;
  }
  $self->_grant( $self->has_username
    ? { grant_type => 'password', username => $self->username, password => $self->password, $self->_client }
    : { grant_type => 'client_credentials', $self->_client } );
  return $self->_access;
}

=method token

    my $bearer = $auth->token;

A token that is valid for at least C<margin> more seconds.

=cut

sub invalidate {
  my ( $self ) = @_;
  $self->_access(undef);
  $self->_refresh(undef);
  return;
}

=method invalidate

    $auth->invalidate;

Forgets the current token, so the next L</token> logs in afresh. Called when
Keycloak refused a token, for example after a restart.

=cut

sub _client {
  my ( $self ) = @_;
  return (
    client_id => $self->has_client_id ? $self->client_id : 'admin-cli',
    defined $self->client_secret ? ( client_secret => $self->client_secret ) : ()
  );
}

sub _grant {
  my ( $self, $form ) = @_;
  my $now  = $self->now->();
  my $data = eval { $self->send_request( POST => $self->token_endpoint, form => $form )->{data} };
  if ( my $error = $@ ) {
    die $error unless ref $error && $error->isa('WWW::Keycloak::Error::API');
    WWW::Keycloak::Error::API->throw(
      message     => 'admin login failed: '.$error->http_status.( defined $error->api_message ? ' - '.$error->api_message : '' ),
      http_status => $error->http_status,
      api_message => $error->api_message,
      oauth_error => $error->oauth_error
    );
  }
  $self->_access( $data->{access_token} );
  $self->_access_expires( $now + ( $data->{expires_in} || 60 ) );
  $self->_refresh( $data->{refresh_token} );
  $self->_refresh_expires( $now + ( $data->{refresh_expires_in} || 0 ) );
  return;
}

1;
```

- [ ] **Step 7: Test laufen lassen**

Run: `prove -lr t/30-auth.t` — Expected: PASS (6 Subtests).

- [ ] **Step 8: Load-Test, Übergabe**

`  WWW::Keycloak::Auth`, `  WWW::Keycloak::Error`, `  WWW::Keycloak::Error::API`, `  WWW::Keycloak::Error::Network`, `  WWW::Keycloak::Error::Validation`, `  WWW::Keycloak::Role::HTTP` in die Liste in `t/00-load.t`, `prove -lr t` — Expected: PASS. Betreff: `Add errors, HTTP role and admin login`; `Changes`: `- WWW::Keycloak::Auth: admin token by password, service account or fixed token, renewed before expiry`.

---

### Task 3: OIDC, Admin-Grundoperationen und die Fassade

Spec: Abschnitte 2, 3, 5.1 und 6.

**Files:**
- Create: `lib/WWW/Keycloak/OIDC.pm`
- Create: `lib/WWW/Keycloak/Admin.pm` (ohne den Abschnitt `ensure`, der folgt in Aufgabe 4)
- Modify: `lib/WWW/Keycloak.pm` (der Stub wird ganz ersetzt)
- Test: `t/20-errors.t`, `t/40-facade.t`, `t/50-admin.t`, `t/60-oidc.t`
- Modify: `t/00-load.t`

**Interfaces:**
- Consumes: alles aus Aufgabe 2; `WWW::Keycloak::Diff` (nur als `diff_class`, benutzt erst in Aufgabe 4).
- Produces:
  - `WWW::Keycloak->new( base_url =>, realm =>, username =>, password =>, client_id =>, client_secret =>, token =>, auth_realm =>, ua => )`; `->issuer`, `->oidc`, `->admin`, `->auth`, `->for_realm($name)`.
  - `WWW::Keycloak::OIDC`: `discovery`, `endpoint($name)`, `token_endpoint`, `userinfo_endpoint`, `introspection_endpoint`, `end_session_endpoint`, `device_endpoint`, `jwks_uri`, `jwks( force_refresh => 1 )`, `verify_token( $jwt, audience => )`, `userinfo($token)`, `introspect( $token, client_id =>, client_secret => )`, `password_token(...)`, `client_credentials_token(...)`, `refresh_token( $refresh, ... )`, `exchange_authorization_code(...)`, `device_authorization(...)`, `device_token(...)`, `logout(...)`.
  - `WWW::Keycloak::Admin`: `call( $method, $path, \%body )` sowie die Methoden aus Spec-Abschnitt 5.1.

- [ ] **Step 1: Die Tests schreiben**

`t/20-errors.t`:

```perl
#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use lib 't/lib';

use Scalar::Util qw( blessed );
use FakeKeycloak;
use WWW::Keycloak;

my $fake = FakeKeycloak->new;
my $kc   = WWW::Keycloak->new( base_url => $fake->base, realm => 'master', username => 'admin', password => 'admin', ua => $fake );

sub error_of (&) { my ( $code ) = @_; eval { $code->(); 1 } ? undef : $@ }

subtest 'classes and stringification' => sub {
  my $e = WWW::Keycloak::Error::API->new( message => 'boom', http_status => 409 );
  isa_ok( $e, 'WWW::Keycloak::Error' );
  is( "$e", 'boom', 'stringifies to the message' );
  ok( $e->is_conflict && !$e->is_not_found && !$e->is_unauthorized, 'predicates' );
  isa_ok( WWW::Keycloak::Error::Validation->new( message => 'x' ), 'WWW::Keycloak::Error' );
  isa_ok( WWW::Keycloak::Error::Network->new( message => 'x' ), 'WWW::Keycloak::Error' );
  my $thrown = error_of { WWW::Keycloak::Error::Validation->throw( message => 'thrown' ) };
  isa_ok( $thrown, 'WWW::Keycloak::Error::Validation', 'throw' );
};

subtest 'the three shapes Keycloak answers errors in' => sub {
  my $conflict = error_of { $kc->admin->create_realm };
  isa_ok( $conflict, 'WWW::Keycloak::Error::API' );
  is( $conflict->http_status, 409, 'status as a number' );
  is( $conflict->api_message, 'Realm master already exists', 'errorMessage' );
  ok( $conflict->is_conflict, 'is_conflict' );
  like( "$conflict", qr{POST http://kc.test/admin/realms failed: 409 .* - Realm master already exists}, 'message names the request' );

  my $missing = error_of { $kc->admin->get_client('nope') };
  ok( $missing->is_not_found, 'is_not_found' );
  is( $missing->api_message, 'Could not find client', 'error' );
  is( $missing->oauth_error, undef, 'an admin error is no OAuth error' );

  my $oauth = error_of { $kc->oidc->password_token( client_id => 'cli', username => 'x', password => 'y' ) };
  is( $oauth->oauth_error, 'invalid_grant', 'oauth_error from the token endpoint' );
  is( $oauth->api_message, 'invalid_grant: Invalid user credentials', 'with the description' );
};

subtest 'no answer at all' => sub {
  my $down = WWW::Keycloak->new( base_url => 'http://127.0.0.1:9', realm => 'x', ua => LWP::UserAgent->new( timeout => 2 ) );
  my $error = error_of { $down->oidc->discovery };
  isa_ok( $error, 'WWW::Keycloak::Error::Network' );
  like( "$error", qr{GET http://127.0.0.1:9/realms/x/.well-known/openid-configuration: 500}, 'names the request' );
};

done_testing;
```

`t/40-facade.t`:

```perl
#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use lib 't/lib';

use FakeKeycloak;
use WWW::Keycloak;

my $fake = FakeKeycloak->new;

subtest 'construction' => sub {
  my $kc = WWW::Keycloak->new( base_url => 'https://id.example.org//', realm => 'main' );
  is( $kc->base_url, 'https://id.example.org', 'trailing slashes go' );
  is( $kc->issuer, 'https://id.example.org/realms/main', 'issuer' );
  isa_ok( $kc->ua, 'LWP::UserAgent' );
  is( $kc->auth, undef, 'no admin login without credentials' );
  isa_ok( $kc->oidc, 'WWW::Keycloak::OIDC' );
  is( $kc->oidc->issuer, $kc->issuer, 'oidc knows the issuer' );
  isa_ok( $kc->admin, 'WWW::Keycloak::Admin' );
  ok( !eval { $kc->admin->get_realm; 1 }, 'the Admin API without credentials' );
  isa_ok( $@, 'WWW::Keycloak::Error::Validation' );
  like( "$@", qr/needs credentials/, 'says what is missing' );

  for my $bad ( [ realm => 'x' ], [ base_url => 'x' ], [ base_url => '', realm => 'x' ], [ base_url => 'x', realm => '' ] ) {
    ok( !eval { WWW::Keycloak->new(@$bad); 1 }, 'refused: '.join( ' ', map { $_ // 'undef' } @$bad ) );
  }
};

subtest 'admin login options' => sub {
  my $pw = WWW::Keycloak->new( base_url => 'http://kc', realm => 'main', username => 'admin', password => 'pw' );
  is( $pw->auth_realm, 'master', 'a password login goes to master' );
  is( $pw->auth->token_endpoint, 'http://kc/realms/master/protocol/openid-connect/token', 'its token endpoint' );
  my $svc = WWW::Keycloak->new( base_url => 'http://kc', realm => 'main', client_id => 'svc', client_secret => 's' );
  is( $svc->auth_realm, 'main', 'a service account logs in to its own realm' );
  my $other = WWW::Keycloak->new( base_url => 'http://kc', realm => 'main', username => 'a', password => 'b', auth_realm => 'admins' );
  like( $other->auth->token_endpoint, qr{/realms/admins/}, 'auth_realm can be set' );
  my $fixed = WWW::Keycloak->new( base_url => 'http://kc', realm => 'main', token => 't' );
  is( $fixed->auth->token, 't', 'a fixed token' );
};

subtest 'for_realm' => sub {
  my $kc  = WWW::Keycloak->new( base_url => $fake->base, realm => 'master', username => 'admin', password => 'admin', ua => $fake );
  my $dev = $kc->for_realm('dev');
  is( $dev->realm, 'dev', 'other realm' );
  is( $dev->issuer, $fake->base.'/realms/dev', 'its issuer' );
  is( $dev->ua, $kc->ua, 'same user agent' );
  is( $dev->auth, $kc->auth, 'same admin login' );
  is( $dev->auth_realm, 'master', 'still logging in to master' );
  $dev->admin->create_realm( { displayName => 'Dev' } );
  is( $fake->realm('dev')->{rep}{displayName}, 'Dev', 'and it works on the other realm' );
  @{ $fake->logins } = ();
  $kc->admin->get_realm;
  $dev->admin->get_realm;
  is( scalar @{ $fake->logins }, 0, 'without logging in again' );
};

done_testing;
```

`t/50-admin.t`:

```perl
#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use lib 't/lib';

use FakeKeycloak;
use WWW::Keycloak;

my $fake = FakeKeycloak->new;
my $kc   = WWW::Keycloak->new( base_url => $fake->base, realm => 'main', username => 'admin', password => 'admin', ua => $fake );
my $admin = $kc->admin;

subtest 'realm' => sub {
  is( $admin->create_realm( { displayName => 'Main' } ), 'main', 'create_realm returns the realm name' );
  is( $admin->get_realm->{displayName}, 'Main', 'get_realm' );
  ok( $admin->update_realm( { accessTokenLifespan => 600 } ), 'update_realm' );
  is( $admin->get_realm->{accessTokenLifespan}, 600, 'updated' );
  is( $admin->get_realm->{displayName}, 'Main', 'the rest untouched' );
  is( $admin->server_info->{systemInfo}{version}, '26.8.0', 'server_info from the server root' );
  my $request = $fake->requests->[-1];
  is( $request->uri->path, '/admin/serverinfo', 'which is not under the realm' );
  is( $request->header('Authorization'), 'Bearer '.$kc->auth->token, 'with the admin token' );
  is( $admin->partial_import( { users => [ { username => 'Imported' } ] }, if_exists => 'SKIP' )->{added}, 1, 'partial_import' );
};

subtest 'clients' => sub {
  my $id = $admin->create_client( { clientId => 'cli', publicClient => \1 } );
  like( $id, qr/\Aid-\d+\z/, 'create_client returns the id from the Location header' );
  is( $admin->get_client($id)->{clientId}, 'cli', 'get_client' );
  is( $admin->find_client('cli')->{id}, $id, 'find_client by clientId' );
  is( $admin->find_client('nope'), undef, 'find_client without a match' );
  my $client = $admin->get_client($id);
  ok( $admin->update_client( $id, { %$client, description => 'd' } ), 'update_client' );
  is( $admin->get_client($id)->{description}, 'd', 'updated' );
  is( scalar @{ $admin->list_clients }, 1, 'list_clients' );
  is( $admin->get_client_secret($id)->{type}, 'secret', 'get_client_secret' );
  is( $admin->get_service_account_user($id)->{username}, 'service-account-cli', 'get_service_account_user' );
  ok( !eval { $admin->create_client( { clientId => 'cli' } ); 1 }, 'a second create croaks' );
  ok( $@->is_conflict, 'with a conflict' );
  ok( $admin->delete_client($id), 'delete_client' );
  ok( !eval { $admin->get_client($id); 1 } && $@->is_not_found, 'gone' );
};

subtest 'client scopes and protocol mappers' => sub {
  my $client = $admin->create_client( { clientId => 'mapped' } );
  my $scope  = $admin->create_client_scope( { name => 'amr', protocol => 'openid-connect' } );
  is( $admin->find_client_scope('amr')->{id}, $scope, 'find_client_scope by name' );
  my $mapper = $admin->create_protocol_mapper( client => $client, { name => 'amr', protocolMapper => 'oidc-amr-mapper', config => {} } );
  ok( $mapper, 'create_protocol_mapper on a client' );
  is( $admin->list_protocol_mappers( client => $client )->[0]{name}, 'amr', 'list_protocol_mappers' );
  ok( $admin->update_protocol_mapper( client => $client, $mapper, { name => 'amr', protocolMapper => 'oidc-amr-mapper', config => { a => 'b' } } ), 'update_protocol_mapper' );
  is( $admin->list_protocol_mappers( client => $client )->[0]{config}{a}, 'b', 'updated' );
  ok( $admin->create_protocol_mapper( client_scope => $scope, { name => 'amr', protocolMapper => 'oidc-amr-mapper' } ), 'on a client scope' );
  like( $fake->requests->[-1]->uri->path, qr{/client-scopes/\Q$scope\E/protocol-mappers/models\z}, 'at the scope' );
  ok( $admin->delete_protocol_mapper( client => $client, $mapper ), 'delete_protocol_mapper' );
  ok( !eval { $admin->list_protocol_mappers( group => 'x' ); 1 }, 'an owner that is neither client nor scope' );
  isa_ok( $@, 'WWW::Keycloak::Error::Validation' );
  ok( $admin->add_default_client_scope( $client, $scope ), 'add_default_client_scope' );
  ok( $admin->add_realm_default_client_scope($scope), 'add_realm_default_client_scope' );
};

subtest 'users' => sub {
  my $id = $admin->create_user( { username => 'Alice', enabled => \1, credentials => [ { type => 'password', value => 'pw', temporary => \0 } ] } );
  is( $admin->find_user('alice')->{id}, $id, 'find_user' );
  is( $admin->find_user('ALICE')->{id}, $id, 'in any case' );
  is( $admin->find_user('alic'), undef, 'exactly' );
  is_deeply( [ map { $_->{type} } @{ $admin->list_credentials($id) } ], ['password'], 'list_credentials' );
  ok( $admin->set_password( $id, 'new', temporary => 1 ), 'set_password' );
  my ( $password ) = grep { $_->{type} eq 'password' } @{ $fake->realm('main')->{users}{$id}{credentials} };
  is_deeply( [ @$password{qw( value type )}, ${ $password->{temporary} } ], [ 'new', 'password', 1 ], 'with type and temporary flag' );
  ok( $admin->update_user( $id, { firstName => 'A' } ), 'update_user' );
  is( $admin->get_user($id)->{firstName}, 'A', 'updated' );
  is_deeply( $admin->list_sessions($id), [], 'list_sessions' );
  ok( $admin->logout_user($id), 'logout_user' );
  ok( $admin->delete_credential( $id, $admin->list_credentials($id)->[0]{id} ), 'delete_credential' );
  ok( $admin->delete_user($id), 'delete_user' );
};

subtest 'authentication' => sub {
  is_deeply( [ map { $_->{alias} } @{ $admin->list_flows } ], [ 'browser', 'direct grant' ], 'list_flows' );
  my ( $otp ) = grep { ( $_->{providerId} // '' ) eq 'auth-otp-form' } @{ $admin->list_executions('browser') };
  ok( $otp, 'list_executions' );
  like( $fake->requests->[-1]->uri->as_string, qr{/flows/browser/executions\z}, 'by alias' );
  $admin->list_executions('direct grant');
  like( $fake->requests->[-1]->uri->as_string, qr{/flows/direct%20grant/executions\z}, 'an alias with a space is escaped' );
  my $config = $admin->create_execution_config( $otp->{id}, { alias => 'x', config => { 'default.reference.value' => 'otp' } } );
  ok( $config, 'create_execution_config' );
  is( $admin->get_execution_config($config)->{config}{'default.reference.value'}, '**********', 'get_execution_config: masked, as Keycloak does' );
  ok( $admin->update_execution_config( $config, { alias => 'x', config => { 'default.reference.value' => 'mfa' } } ), 'update_execution_config' );
  is( $fake->realm('main')->{configs}{$config}{config}{'default.reference.value'}, 'mfa', 'updated' );
  is( $fake->realm('main')->{configs}{$config}{id}, $config, 'with its id' );
  ok( $admin->copy_flow( 'browser', 'browser-copy' ), 'copy_flow' );
  is_deeply( $admin->describe_authenticator('auth-otp-form'), { properties => [] }, 'describe_authenticator' );
};

subtest 'call reaches what has no method' => sub {
  my $result = $admin->call( GET => '/clients?first=0&max=1' );
  is( $result->{status}, 200, 'status' );
  is( ref $result->{data}, 'ARRAY', 'data' );
};

subtest 'a refused token is renewed once' => sub {
  $admin->get_realm;
  @{ $fake->logins } = ();
  $fake->forget_tokens;
  ok( $admin->get_realm, 'the call after a Keycloak restart succeeds' );
  is( scalar @{ $fake->logins }, 1, 'after one new login' );

  my $fixed = WWW::Keycloak->new( base_url => $fake->base, realm => 'main', token => 'stale', ua => $fake );
  ok( !eval { $fixed->admin->get_realm; 1 }, 'a fixed token that is refused croaks' );
  ok( $@->is_unauthorized, 'with 401' );

  my $always = WWW::Keycloak->new( base_url => $fake->base, realm => 'main', username => 'admin', password => 'admin', ua => $fake );
  no warnings 'redefine';
  local *FakeKeycloak::_admin = sub { $_[0]->_reply( 401, { error => 'HTTP 401 Unauthorized' } ) };
  @{ $fake->logins } = ();
  ok( !eval { $always->admin->get_realm; 1 }, 'a token refused twice croaks' );
  is( scalar @{ $fake->logins }, 2, 'after exactly one retry' );
};

done_testing;
```

`t/60-oidc.t`:

```perl
#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use lib 't/lib';

use Crypt::PK::RSA;
use MIME::Base64 qw( encode_base64url );
use FakeKeycloak;
use WWW::Keycloak;

my $fake = FakeKeycloak->new;
$fake->add_realm('main');
my $oidc   = WWW::Keycloak->new( base_url => $fake->base, realm => 'main', ua => $fake )->oidc;
my $issuer = $fake->base.'/realms/main';

sub claims { { iss => $issuer, sub => 'u-1', aud => 'my-api', exp => time + 300, iat => time, @_ } }

subtest 'discovery' => sub {
  is( $oidc->token_endpoint, $issuer.'/protocol/openid-connect/token', 'token_endpoint' );
  is( $oidc->device_endpoint, $issuer.'/protocol/openid-connect/auth/device', 'device_endpoint' );
  my $count = grep { $_->uri =~ /well-known/ } @{ $fake->requests };
  $oidc->userinfo_endpoint;
  is( scalar( grep { $_->uri =~ /well-known/ } @{ $fake->requests } ), $count, 'fetched once' );
  ok( !eval { $oidc->endpoint('nope_endpoint'); 1 }, 'a missing endpoint croaks' );
  like( "$@", qr/has no nope_endpoint/, 'and names it' );
};

subtest 'verify_token' => sub {
  my $claims = $oidc->verify_token( $fake->sign( claims() ), audience => 'my-api' );
  is( $claims->{sub}, 'u-1', 'a good token' );
  ok( $oidc->verify_token( $fake->sign( claims() ) ), 'audience is only checked when asked' );
  my %bad = (
    'wrong issuer'   => $fake->sign( claims( iss => 'https://evil/realms/main' ) ),
    'expired'        => $fake->sign( claims( exp => time - 10 ) ),
    'wrong audience' => $fake->sign( claims( aud => 'other' ) ),
    'foreign key'    => do { my $k = Crypt::PK::RSA->new; $k->generate_key( 256, 65537 ); $fake->sign( claims(), key => $k ) },
    'HMAC'           => $fake->sign( claims(), alg => 'HS256', key => 'secret' ),
    'not a JWT'      => 'abc.def'
  );
  for my $case ( sort keys %bad ) {
    ok( !eval { $oidc->verify_token( $bad{$case}, audience => 'my-api' ); 1 }, $case.' is rejected' );
    isa_ok( $@, 'WWW::Keycloak::Error::Validation' );
  }
  my ( $none ) = map { join '.', $_, encode_base64url('{"iss":"'.$issuer.'","sub":"x","exp":'.( time + 60 ).'}'), '' } encode_base64url('{"alg":"none"}');
  ok( !eval { $oidc->verify_token($none); 1 }, 'alg none is rejected' );
  ok( !eval { $oidc->verify_token(''); 1 }, 'an empty token' );
};

subtest 'key rotation' => sub {
  $oidc->jwks;
  $fake->rotate_key;
  my $before = grep { $_->uri =~ /certs/ } @{ $fake->requests };
  ok( $oidc->verify_token( $fake->sign( claims() ) ), 'a token signed with a new key verifies' );
  is( scalar( grep { $_->uri =~ /certs/ } @{ $fake->requests } ), $before + 1, 'after fetching the keys once more' );
};

subtest 'token endpoint' => sub {
  my $tokens = $oidc->password_token( client_id => 'admin-cli', username => 'admin', password => 'admin', totp => '123456', scope => 'openid' );
  like( $tokens->{access_token}, qr/\Aat-/, 'password_token' );
  is_deeply( { map { $_ => $fake->logins->[-1]{$_} } qw( grant_type username totp scope client_id ) },
    { grant_type => 'password', username => 'admin', totp => '123456', scope => 'openid', client_id => 'admin-cli' }, 'sends totp and scope' );
  ok( $oidc->client_credentials_token( client_id => 'svc', client_secret => 'secret' )->{access_token}, 'client_credentials_token' );
  ok( $oidc->refresh_token( $tokens->{refresh_token}, client_id => 'admin-cli' )->{access_token}, 'refresh_token' );
  ok( !eval { $oidc->password_token( username => 'a', password => 'b' ); 1 }, 'without client_id' );
  isa_ok( $@, 'WWW::Keycloak::Error::Validation' );
};

subtest 'device flow, one step at a time' => sub {
  my $start = $oidc->device_authorization( client_id => 'cli', scope => 'openid' );
  is( $start->{user_code}, 'ABCD-EFGH', 'device_authorization' );
  ok( !eval { $oidc->device_token( device_code => $start->{device_code}, client_id => 'cli' ); 1 }, 'a pending poll croaks' );
  is( $@->oauth_error, 'authorization_pending', 'with oauth_error authorization_pending' );
};

subtest 'userinfo, introspect, logout' => sub {
  is( $oidc->userinfo('user-token')->{preferred_username}, 'alice', 'userinfo' );
  ok( !eval { $oidc->userinfo('bad'); 1 } && $@->is_unauthorized, 'userinfo with a bad token' );
  ok( $oidc->introspect( 'user-token', client_id => 'api', client_secret => 's' )->{active}, 'introspect' );
  ok( $oidc->logout( refresh_token => 'r', client_id => 'cli' ), 'logout' );
};

done_testing;
```

- [ ] **Step 2: Tests laufen lassen, sie müssen scheitern**

Run: `prove -lr t/20-errors.t t/40-facade.t t/50-admin.t t/60-oidc.t` — Expected: FAIL; der Stub `WWW::Keycloak` hat kein `new` mit diesen Attributen.

- [ ] **Step 3: `lib/WWW/Keycloak/OIDC.pm` schreiben**

`lib/WWW/Keycloak/OIDC.pm`:

```perl
package WWW::Keycloak::OIDC;

# ABSTRACT: OpenID Connect against one Keycloak realm

use Moo;
with 'WWW::Keycloak::Role::HTTP';
use Crypt::JWT qw( decode_jwt );
use Scalar::Util qw( blessed );
use Types::Standard qw( ArrayRef InstanceOf Str );
use WWW::Keycloak::Error::Validation;
use namespace::autoclean;

our $VERSION = '0.001';

=synopsis

    my $oidc = WWW::Keycloak->new( base_url => $url, realm => 'main' )->oidc;

    my $claims = $oidc->verify_token( $jwt, audience => 'my-api' );
    my $tokens = $oidc->password_token( client_id => 'cli', username => 'alice', password => $pw, totp => '123456' );

=description

The OpenID Connect side of a realm: discovery, the signing keys, token
verification, and the token endpoint in all the grant types Keycloak offers.

Endpoints come from the realm's discovery document, fetched once and kept.
An error from the token endpoint is a L<WWW::Keycloak::Error::API> whose
C<oauth_error> carries the OAuth code, so a device-flow poll can tell
C<authorization_pending> from a real failure.

=cut

has issuer => (
  is       => 'ro',
  isa      => Str,
  required => 1
);

=attr issuer

Required. C<< <base_url>/realms/<realm> >>.

=cut

has ua => (
  is       => 'ro',
  isa      => InstanceOf['LWP::UserAgent'],
  required => 1
);

=attr ua

Required. The L<LWP::UserAgent> to use.

=cut

has algorithms => (
  is      => 'ro',
  isa     => ArrayRef[Str],
  default => sub { [qw( RS256 RS384 RS512 PS256 PS384 PS512 ES256 ES384 ES512 )] }
);

=attr algorithms

Signature algorithms L</verify_token> accepts. Never C<none>, never HMAC.

=cut

has discovery => (
  is       => 'lazy',
  init_arg => undef
);

sub _build_discovery {
  my ( $self ) = @_;
  my $data = $self->send_request( GET => $self->issuer.'/.well-known/openid-configuration' )->{data};
  WWW::Keycloak::Error::Validation->throw( message => 'discovery for '.$self->issuer.' returned no JSON object' ) unless ref $data eq 'HASH';
  return $data;
}

=attr discovery

The discovery document, fetched on first use.

=cut

has _jwks => (
  is       => 'rw',
  init_arg => undef
);

sub endpoint {
  my ( $self, $name ) = @_;
  my $url = $self->discovery->{$name};
  WWW::Keycloak::Error::Validation->throw( message => 'the discovery document of '.$self->issuer.' has no '.$name ) unless defined $url;
  return $url;
}

=method endpoint

    my $url = $oidc->endpoint('device_authorization_endpoint');

A URL from the discovery document. Throws when it is missing.

=cut

sub token_endpoint         { $_[0]->endpoint('token_endpoint') }
sub userinfo_endpoint      { $_[0]->endpoint('userinfo_endpoint') }
sub introspection_endpoint { $_[0]->endpoint('introspection_endpoint') }
sub end_session_endpoint   { $_[0]->endpoint('end_session_endpoint') }
sub device_endpoint        { $_[0]->endpoint('device_authorization_endpoint') }
sub jwks_uri               { $_[0]->endpoint('jwks_uri') }

sub jwks {
  my ( $self, %opt ) = @_;
  $self->_jwks( $self->send_request( GET => $self->jwks_uri )->{data} ) if $opt{force_refresh} || !$self->_jwks;
  return $self->_jwks;
}

=method jwks

    my $keys = $oidc->jwks;
    my $keys = $oidc->jwks( force_refresh => 1 );

The realm's public signing keys, kept after the first fetch.

=cut

sub verify_token {
  my ( $self, $token, %opt ) = @_;
  WWW::Keycloak::Error::Validation->throw( message => 'verify_token needs a token' ) unless defined $token && length $token;
  my %check = (
    token          => $token,
    verify_iss     => $self->issuer,
    verify_exp     => 1,
    accepted_alg   => $self->algorithms,
    decode_payload => 1,
    defined $opt{audience} ? ( verify_aud => $opt{audience} ) : ()
  );
  my $claims = eval { decode_jwt( %check, kid_keys => $self->jwks ) };
  return $claims if $claims;
  my $first = $@;
  # a key Keycloak rotated in since the keys were fetched
  $claims = eval { decode_jwt( %check, kid_keys => $self->jwks( force_refresh => 1 ) ) };
  return $claims if $claims;
  WWW::Keycloak::Error::Validation->throw( message => 'token rejected: '.( $@ || $first ) =~ s/ at \S+ line \d+.*//sr );
}

=method verify_token

    my $claims = $oidc->verify_token( $jwt, audience => 'my-api' );

Checks signature, issuer and expiry, and the audience when one is given.
Fetches the keys again once when the signing key is unknown. Returns the
claims, or throws a validation error saying why the token was rejected.

=cut

sub userinfo {
  my ( $self, $access_token ) = @_;
  return $self->send_request( GET => $self->userinfo_endpoint, bearer => $access_token )->{data};
}

=method userinfo

    my $info = $oidc->userinfo($access_token);

=cut

sub introspect {
  my ( $self, $token, %client ) = @_;
  return $self->_token_call( $self->introspection_endpoint, { token => $token }, %client );
}

=method introspect

    my $state = $oidc->introspect( $token, client_id => 'api', client_secret => $secret );

Needs a confidential client.

=cut

sub password_token {
  my ( $self, %arg ) = @_;
  return $self->_grant( password => [qw( username password totp scope )], %arg );
}

sub client_credentials_token {
  my ( $self, %arg ) = @_;
  return $self->_grant( client_credentials => ['scope'], %arg );
}

sub refresh_token {
  my ( $self, $refresh, %arg ) = @_;
  return $self->_grant( refresh_token => [qw( refresh_token scope )], %arg, refresh_token => $refresh );
}

sub exchange_authorization_code {
  my ( $self, %arg ) = @_;
  return $self->_grant( authorization_code => [qw( code redirect_uri code_verifier )], %arg );
}

sub device_token {
  my ( $self, %arg ) = @_;
  return $self->_grant( 'urn:ietf:params:oauth:grant-type:device_code' => ['device_code'], %arg );
}

=method password_token

    my $tokens = $oidc->password_token( client_id => 'cli', username => 'alice', password => $pw, totp => '123456', scope => 'openid' );

The direct grant. C<totp> is needed for users with a one-time password.

=method client_credentials_token

    my $tokens = $oidc->client_credentials_token( client_id => 'svc', client_secret => $secret );

=method refresh_token

    my $tokens = $oidc->refresh_token( $refresh, client_id => 'cli' );

=method exchange_authorization_code

    my $tokens = $oidc->exchange_authorization_code( code => $code, redirect_uri => $uri, client_id => 'web', client_secret => $secret );

=method device_token

    my $tokens = eval { $oidc->device_token( device_code => $start->{device_code}, client_id => 'cli' ) };
    # $@->oauth_error eq 'authorization_pending' while nobody has approved

One poll of the device flow. The loop is the caller's, or L<Airlock::Client>'s.

=cut

sub device_authorization {
  my ( $self, %arg ) = @_;
  return $self->_token_call( $self->device_endpoint, { defined $arg{scope} ? ( scope => $arg{scope} ) : () }, %arg );
}

=method device_authorization

    my $start = $oidc->device_authorization( client_id => 'cli', scope => 'openid' );

Starts a device flow: C<device_code>, C<user_code>, C<verification_uri>,
C<verification_uri_complete>, C<expires_in>, C<interval>.

=cut

sub logout {
  my ( $self, %arg ) = @_;
  $self->_token_call( $self->end_session_endpoint, { refresh_token => $arg{refresh_token} }, %arg );
  return 1;
}

=method logout

    $oidc->logout( refresh_token => $refresh, client_id => 'cli' );

Ends the session the refresh token belongs to.

=cut

sub _grant {
  my ( $self, $type, $fields, %arg ) = @_;
  return $self->_token_call( $self->token_endpoint, { grant_type => $type, map { $_ => $arg{$_} } grep { defined $arg{$_} } @$fields }, %arg );
}

sub _token_call {
  my ( $self, $url, $form, %arg ) = @_;
  WWW::Keycloak::Error::Validation->throw( message => 'a client_id is needed' ) unless defined $arg{client_id};
  my %form = ( %$form, client_id => $arg{client_id}, defined $arg{client_secret} ? ( client_secret => $arg{client_secret} ) : () );
  return $self->send_request( POST => $url, form => \%form )->{data} // {};
}

1;
```

- [ ] **Step 4: `lib/WWW/Keycloak/Admin.pm` schreiben**

Die Methoden sind absichtlich dünn: ein Endpunkt je Methode. `create_*` liest die ID aus dem `Location`-Header, weil Keycloak beim Anlegen keinen Body schickt.

`lib/WWW/Keycloak/Admin.pm`:

```perl
package WWW::Keycloak::Admin;

# ABSTRACT: Keycloak Admin REST API for one realm, with idempotent ensure methods

use Moo;
with 'WWW::Keycloak::Role::HTTP';
use Scalar::Util qw( blessed );
use Types::Standard qw( InstanceOf Str );
use URI::Escape qw( uri_escape_utf8 );
use WWW::Keycloak::Diff;
use WWW::Keycloak::Error::Validation;
use namespace::autoclean;

our $VERSION = '0.001';

=synopsis

    my $admin = WWW::Keycloak->new( base_url => $url, realm => 'main', username => 'admin', password => $pw )->admin;

    # one call, one endpoint
    my $client = $admin->find_client('my-cli');
    my $id     = $admin->create_user( { username => 'alice', enabled => \1 } );

    # wanted state, as often as you like
    my $r = $admin->ensure_client( clientId => 'my-cli', publicClient => \1 );
    print $r->{changed};   # 'created', 'updated' or ''

=description

The Admin REST API of the realm the L<WWW::Keycloak> facade was made for.

The basic methods are one endpoint each. C<get_*> and C<find_*> return the
representation as a hash (C<find_*> returns nothing when there is no match),
C<list_*> an array reference, C<create_*> the id of the new object, which
Keycloak sends in the C<Location> header, and C<update_*> and C<delete_*> true.
Every failure is a L<WWW::Keycloak::Error::API>; C<is_not_found> and
C<is_conflict> tell the common cases apart.

The C<ensure_*> methods are what makes a setup repeatable. Each looks the
object up by its readable key, creates it when it is missing, otherwise writes
only what differs, and returns C<< { id => ..., changed => 'created' | 'updated' | '' } >>.
Only the keys given are compared; nothing is ever deleted.

When Keycloak refuses the token (HTTP 401), the request is repeated once with
a fresh one.

=cut

has base_url => (
  is       => 'ro',
  isa      => Str,
  required => 1
);

=attr base_url

Required. The Keycloak URL without C</realms/...>.

=cut

has realm => (
  is       => 'ro',
  isa      => Str,
  required => 1
);

=attr realm

Required. The realm every method works on.

=cut

has ua => (
  is       => 'ro',
  isa      => InstanceOf['LWP::UserAgent'],
  required => 1
);

=attr ua

Required. The L<LWP::UserAgent> to use.

=cut

has auth => (
  is        => 'ro',
  isa       => InstanceOf['WWW::Keycloak::Auth'],
  predicate => 'has_auth'
);

=attr auth

The L<WWW::Keycloak::Auth> that supplies the admin token. Without it every
call throws a validation error.

=cut

sub diff_class { 'WWW::Keycloak::Diff' }

####  transport

sub realm_url { $_[0]->base_url.'/admin/realms/'.uri_escape_utf8( $_[0]->realm ) }

sub call {
  my ( $self, $method, $path, $body ) = @_;
  my $url = $path =~ m{\A/admin/} ? $self->base_url.$path : $self->realm_url.$path;
  WWW::Keycloak::Error::Validation->throw( message => 'the Admin API needs credentials: give username and password, client_id and client_secret, or token' )
    unless $self->has_auth;
  my %arg = defined $body ? ( json => $body ) : ();
  my $result = eval { $self->send_request( $method, $url, %arg, bearer => $self->auth->token ) };
  if ( my $error = $@ ) {
    die $error unless blessed $error && $error->isa('WWW::Keycloak::Error::API') && $error->is_unauthorized && $self->auth->renewable;
    $self->auth->invalidate;
    $result = $self->send_request( $method, $url, %arg, bearer => $self->auth->token );
  }
  return $result;
}

=method call

    my $result = $admin->call( GET => '/clients?clientId=x' );
    my $result = $admin->call( POST => '/admin/realms', { realm => 'new' } );

One request against the Admin API. A path starting with C</admin/> is taken
from the server root, anything else from the realm. Returns what
L<WWW::Keycloak::Role::HTTP/send_request> returns. The way to reach an
endpoint this class has no method for.

=cut

sub _data   { $_[0]->call( @_[ 1 .. $#_ ] )->{data} }
sub _done   { $_[0]->call( @_[ 1 .. $#_ ] ); 1 }
sub _create {
  my ( $self, $path, $body ) = @_;
  my $location = $self->call( POST => $path, $body )->{location} // '';
  my ( $id ) = $location =~ m{/([^/]+)\z};
  return $id;
}
sub _esc { uri_escape_utf8( $_[1] ) }

sub _query {
  my ( $self, %query ) = @_;
  return '' unless %query;
  return '?'.join '&', map { $self->_esc($_).'='.$self->_esc( $query{$_} ) } sort keys %query;
}

sub _missing {
  my ( $self, $error ) = @_;
  return 1 if blessed $error && $error->isa('WWW::Keycloak::Error::API') && $error->is_not_found;
  die $error;
}

####  server and realm

sub server_info { $_[0]->_data( GET => '/admin/serverinfo' ) }

sub get_realm    { $_[0]->_data( GET => '' ) }
sub update_realm { $_[0]->_done( PUT => '', $_[1] ) }
sub delete_realm { $_[0]->_done( DELETE => '' ) }

sub create_realm {
  my ( $self, $rep ) = @_;
  $self->call( POST => '/admin/realms', { realm => $self->realm, %{ $rep || {} } } );
  return $self->realm;
}

sub export_realm {
  my ( $self, %opt ) = @_;
  return $self->_data( POST => '/partial-export'.$self->_query(
    exportClients        => $opt{clients} ? 'true' : 'false',
    exportGroupsAndRoles => $opt{groups_and_roles} ? 'true' : 'false'
  ) );
}

sub partial_import {
  my ( $self, $rep, %opt ) = @_;
  return $self->_data( POST => '/partialImport', { ifResourceExists => $opt{if_exists} // 'FAIL', %$rep } );
}

=method server_info

=method get_realm

=method create_realm

    $admin->create_realm( { enabled => \1 } );   # the realm of this object

=method update_realm

    $admin->update_realm( { accessTokenLifespan => 600 } );

Keycloak takes a partial representation here and leaves the rest alone.

=method delete_realm

=method export_realm

    my $rep = $admin->export_realm( clients => 1, groups_and_roles => 0 );

Keycloak masks secrets and authenticator settings in the export.

=method partial_import

    my $summary = $admin->partial_import( { users => [ ... ] }, if_exists => 'SKIP' );

C<if_exists> is C<FAIL> (default), C<SKIP> or C<OVERWRITE>.

=cut

####  clients

sub list_clients  { my ( $self, %q ) = @_; $self->_data( GET => '/clients'.$self->_query(%q) ) }
sub get_client    { $_[0]->_data( GET => '/clients/'.$_[0]->_esc( $_[1] ) ) }
sub create_client { $_[0]->_create( '/clients', $_[1] ) }
sub update_client { $_[0]->_done( PUT => '/clients/'.$_[0]->_esc( $_[1] ), $_[2] ) }
sub delete_client { $_[0]->_done( DELETE => '/clients/'.$_[0]->_esc( $_[1] ) ) }

sub find_client {
  my ( $self, $client_id ) = @_;
  my ( $client ) = grep { $_->{clientId} eq $client_id } @{ $self->list_clients( clientId => $client_id ) };
  return $client;
}

sub get_client_secret        { $_[0]->_data( GET => '/clients/'.$_[0]->_esc( $_[1] ).'/client-secret' ) }
sub regenerate_client_secret { $_[0]->_data( POST => '/clients/'.$_[0]->_esc( $_[1] ).'/client-secret' ) }
sub get_service_account_user { $_[0]->_data( GET => '/clients/'.$_[0]->_esc( $_[1] ).'/service-account-user' ) }

=method list_clients

    my $clients = $admin->list_clients( first => 0, max => 50 );

=method find_client

    my $client = $admin->find_client('my-cli') or die 'no such client';

By C<clientId>, the readable key. Everything else takes the internal C<id>.

=method get_client

=method create_client

=method update_client

    $admin->update_client( $id, { %$client, description => 'new' } );

Send the whole representation; L</ensure_client> does that for you.

=method delete_client

=method get_client_secret

=method regenerate_client_secret

=method get_service_account_user

=cut

####  client scopes

sub list_client_scopes  { $_[0]->_data( GET => '/client-scopes' ) }
sub get_client_scope    { $_[0]->_data( GET => '/client-scopes/'.$_[0]->_esc( $_[1] ) ) }
sub create_client_scope { $_[0]->_create( '/client-scopes', $_[1] ) }
sub update_client_scope { $_[0]->_done( PUT => '/client-scopes/'.$_[0]->_esc( $_[1] ), $_[2] ) }
sub delete_client_scope { $_[0]->_done( DELETE => '/client-scopes/'.$_[0]->_esc( $_[1] ) ) }

sub find_client_scope {
  my ( $self, $name ) = @_;
  my ( $scope ) = grep { $_->{name} eq $name } @{ $self->list_client_scopes };
  return $scope;
}

sub add_default_client_scope {
  my ( $self, $client, $scope ) = @_;
  return $self->_done( PUT => '/clients/'.$self->_esc($client).'/default-client-scopes/'.$self->_esc($scope) );
}

sub add_realm_default_client_scope { $_[0]->_done( PUT => '/default-default-client-scopes/'.$_[0]->_esc( $_[1] ) ) }

=method list_client_scopes

=method find_client_scope

    my $scope = $admin->find_client_scope('amr');

By C<name>.

=method get_client_scope

=method create_client_scope

=method update_client_scope

=method delete_client_scope

=method add_default_client_scope

    $admin->add_default_client_scope( $client_id, $scope_id );   # both internal ids

=method add_realm_default_client_scope

    $admin->add_realm_default_client_scope($scope_id);

New clients of the realm get this scope.

=cut

####  protocol mappers

sub _mapper_path {
  my ( $self, $kind, $owner ) = @_;
  WWW::Keycloak::Error::Validation->throw( message => 'protocol mappers belong to a client or a client_scope, not to '.( $kind // 'nothing' ) )
    unless defined $kind && ( $kind eq 'client' || $kind eq 'client_scope' );
  return ( $kind eq 'client' ? '/clients/' : '/client-scopes/' ).$self->_esc($owner).'/protocol-mappers/models';
}

sub list_protocol_mappers  { my ( $self, $kind, $owner ) = @_; $self->_data( GET => $self->_mapper_path( $kind, $owner ) ) }
sub create_protocol_mapper { my ( $self, $kind, $owner, $rep ) = @_; $self->_create( $self->_mapper_path( $kind, $owner ), $rep ) }

sub update_protocol_mapper {
  my ( $self, $kind, $owner, $id, $rep ) = @_;
  return $self->_done( PUT => $self->_mapper_path( $kind, $owner ).'/'.$self->_esc($id), $rep );
}

sub delete_protocol_mapper {
  my ( $self, $kind, $owner, $id ) = @_;
  return $self->_done( DELETE => $self->_mapper_path( $kind, $owner ).'/'.$self->_esc($id) );
}

=method list_protocol_mappers

    my $mappers = $admin->list_protocol_mappers( client => $client_id );
    my $mappers = $admin->list_protocol_mappers( client_scope => $scope_id );

=method create_protocol_mapper

    my $id = $admin->create_protocol_mapper( client => $client_id, { name => 'amr', protocol => 'openid-connect', protocolMapper => 'oidc-amr-mapper', config => {...} } );

=method update_protocol_mapper

    $admin->update_protocol_mapper( client => $client_id, $mapper_id, \%rep );

=method delete_protocol_mapper

    $admin->delete_protocol_mapper( client_scope => $scope_id, $mapper_id );

=cut

####  users

sub list_users  { my ( $self, %q ) = @_; $self->_data( GET => '/users'.$self->_query(%q) ) }
sub get_user    { $_[0]->_data( GET => '/users/'.$_[0]->_esc( $_[1] ) ) }
sub create_user { $_[0]->_create( '/users', $_[1] ) }
sub update_user { $_[0]->_done( PUT => '/users/'.$_[0]->_esc( $_[1] ), $_[2] ) }
sub delete_user { $_[0]->_done( DELETE => '/users/'.$_[0]->_esc( $_[1] ) ) }

sub find_user {
  my ( $self, $username ) = @_;
  my ( $user ) = grep { lc $_->{username} eq lc $username } @{ $self->list_users( username => $username, exact => 'true' ) };
  return $user;
}

sub set_password {
  my ( $self, $id, $password, %opt ) = @_;
  return $self->_done( PUT => '/users/'.$self->_esc($id).'/reset-password',
    { type => 'password', value => $password, temporary => $opt{temporary} ? \1 : \0 } );
}

sub list_credentials  { $_[0]->_data( GET => '/users/'.$_[0]->_esc( $_[1] ).'/credentials' ) }
sub delete_credential { $_[0]->_done( DELETE => '/users/'.$_[0]->_esc( $_[1] ).'/credentials/'.$_[0]->_esc( $_[2] ) ) }
sub list_sessions     { $_[0]->_data( GET => '/users/'.$_[0]->_esc( $_[1] ).'/sessions' ) }
sub logout_user       { $_[0]->_done( POST => '/users/'.$_[0]->_esc( $_[1] ).'/logout' ) }

=method list_users

    my $users = $admin->list_users( search => 'ali', max => 20 );

=method find_user

    my $user = $admin->find_user('alice');

By C<username>, exactly; Keycloak stores user names in lower case.

=method get_user

=method create_user

    my $id = $admin->create_user( { username => 'alice', enabled => \1, credentials => [ { type => 'password', value => $pw, temporary => \0 } ] } );

=method update_user

=method delete_user

=method set_password

    $admin->set_password( $id, $password, temporary => 0 );

=method list_credentials

=method delete_credential

=method list_sessions

=method logout_user

=cut

####  authentication

sub list_flows       { $_[0]->_data( GET => '/authentication/flows' ) }
sub list_executions  { $_[0]->_data( GET => '/authentication/flows/'.$_[0]->_esc( $_[1] ).'/executions' ) }
sub copy_flow        { $_[0]->_create( '/authentication/flows/'.$_[0]->_esc( $_[1] ).'/copy', { newName => $_[2] } ) }
sub get_execution_config    { $_[0]->_data( GET => '/authentication/config/'.$_[0]->_esc( $_[1] ) ) }
sub create_execution_config { $_[0]->_create( '/authentication/executions/'.$_[0]->_esc( $_[1] ).'/config', $_[2] ) }
sub update_execution_config { $_[0]->_done( PUT => '/authentication/config/'.$_[0]->_esc( $_[1] ), { %{ $_[2] }, id => $_[1] } ) }
sub describe_authenticator  { $_[0]->_data( GET => '/authentication/config-description/'.$_[0]->_esc( $_[1] ) ) }

=method list_flows

=method list_executions

    my $steps = $admin->list_executions('browser');

All steps of a flow and its sub-flows, flat, each with C<level>,
C<providerId> and C<authenticationConfig>.

=method copy_flow

=method get_execution_config

=method create_execution_config

    my $config_id = $admin->create_execution_config( $execution_id, { alias => 'x', config => {...} } );

Works on the built-in flows too.

=method update_execution_config

    $admin->update_execution_config( $config_id, { alias => 'x', config => {...} } );

=method describe_authenticator

=cut

1;
```

- [ ] **Step 5: `lib/WWW/Keycloak.pm` ersetzen**

`lib/WWW/Keycloak.pm`:

```perl
package WWW::Keycloak;

# ABSTRACT: Perl client for Keycloak identity management (OIDC + Admin REST API)

use Moo;
use LWP::UserAgent;
use Types::Standard qw( InstanceOf Str );
use WWW::Keycloak::Admin;
use WWW::Keycloak::Auth;
use WWW::Keycloak::Error;
use WWW::Keycloak::Error::API;
use WWW::Keycloak::Error::Network;
use WWW::Keycloak::Error::Validation;
use WWW::Keycloak::OIDC;
use namespace::autoclean;

our $VERSION = '0.001';

=synopsis

    use WWW::Keycloak;

    my $kc = WWW::Keycloak->new(
      base_url => 'https://id.example.org',
      realm    => 'main',
      username => 'admin',            # or client_id + client_secret, or token
      password => $ENV{KEYCLOAK_ADMIN_PASSWORD},
    );

    # OpenID Connect
    my $claims = $kc->oidc->verify_token( $jwt, audience => 'my-api' );

    # Admin REST API, repeatable
    $kc->admin->ensure_client( clientId => 'my-cli', publicClient => \1 );
    $kc->admin->ensure_user( username => 'alice', enabled => \1 );

    # another realm, same login
    my $dev = $kc->for_realm('dev');

=description

A client for Keycloak in two parts: L<WWW::Keycloak::OIDC> for what an
application does with a realm, and L<WWW::Keycloak::Admin> for bringing a
realm into a wanted state from Perl, repeatably.

The realm is part of every address in Keycloak, so it is a required attribute
here and not an argument of each method. L</for_realm> gives the same client
for another realm.

The admin login is managed for you: L<WWW::Keycloak::Auth> fetches a token,
renews it before it runs out and once more when Keycloak refuses it.

=cut

has base_url => (
  is       => 'ro',
  isa      => Str,
  required => 1
);

=attr base_url

Required. Where Keycloak is, without C</realms/...>. A trailing slash is
removed.

=cut

has realm => (
  is       => 'ro',
  isa      => Str,
  required => 1
);

=attr realm

Required. The realm to work with.

=cut

has username      => ( is => 'ro', isa => Str, predicate => 'has_username' );
has password      => ( is => 'ro', isa => Str );
has client_id     => ( is => 'ro', isa => Str, predicate => 'has_client_id' );
has client_secret => ( is => 'ro', isa => Str );
has token         => ( is => 'ro', isa => Str, predicate => 'has_token' );

=attr username

=attr password

Admin login with a password, through the C<admin-cli> client of
L</auth_realm>.

=attr client_id

=attr client_secret

Admin login as a service-account client.

=attr token

A ready admin token, used as it is.

=cut

has auth_realm => (
  is  => 'lazy',
  isa => Str
);

sub _build_auth_realm { $_[0]->has_username ? 'master' : $_[0]->realm }

=attr auth_realm

The realm the admin logs in to. Default C<master> for a password login, the
own realm for a service account.

=cut

has ua => (
  is  => 'lazy',
  isa => InstanceOf['LWP::UserAgent']
);

sub _build_ua {
  return LWP::UserAgent->new( timeout => 30, agent => 'WWW-Keycloak/'.$VERSION, ssl_opts => { verify_hostname => 1 } );
}

=attr ua

The L<LWP::UserAgent> every part shares.

=cut

has auth => (
  is  => 'lazy',
  isa => InstanceOf['WWW::Keycloak::Auth'] | Types::Standard::Undef
);

sub _build_auth {
  my ( $self ) = @_;
  return WWW::Keycloak::Auth->new( ua => $self->ua, token => $self->token ) if $self->has_token;
  return unless $self->has_username || $self->has_client_id;
  return WWW::Keycloak::Auth->new(
    ua             => $self->ua,
    token_endpoint => $self->base_url.'/realms/'.$self->auth_realm.'/protocol/openid-connect/token',
    map { $_ => $self->$_ } grep { defined $self->$_ } qw( username password client_id client_secret )
  );
}

=attr auth

The L<WWW::Keycloak::Auth>, or undef when no admin login was given.

=cut

has oidc => (
  is       => 'lazy',
  init_arg => undef
);

sub _build_oidc {
  my ( $self ) = @_;
  return WWW::Keycloak::OIDC->new( issuer => $self->issuer, ua => $self->ua );
}

=attr oidc

The L<WWW::Keycloak::OIDC> of this realm.

=cut

has admin => (
  is       => 'lazy',
  init_arg => undef
);

sub _build_admin {
  my ( $self ) = @_;
  return WWW::Keycloak::Admin->new(
    base_url => $self->base_url,
    realm    => $self->realm,
    ua       => $self->ua,
    $self->auth ? ( auth => $self->auth ) : ()
  );
}

=attr admin

The L<WWW::Keycloak::Admin> of this realm.

=cut

around BUILDARGS => sub {
  my ( $orig, $class, @args ) = @_;
  my $args = $class->$orig(@args);
  $args->{base_url} =~ s{/+\z}{} if defined $args->{base_url};
  return $args;
};

sub BUILD {
  my ( $self ) = @_;
  for (qw( base_url realm )) {
    WWW::Keycloak::Error::Validation->throw( message => __PACKAGE__.' needs a '.$_ ) unless length $self->$_;
  }
  return;
}

sub issuer { $_[0]->base_url.'/realms/'.$_[0]->realm }

=method issuer

    print $kc->issuer;   # https://id.example.org/realms/main

=cut

sub for_realm {
  my ( $self, $realm ) = @_;
  return ref($self)->new(
    base_url   => $self->base_url,
    realm      => $realm,
    ua         => $self->ua,
    auth_realm => $self->auth_realm,
    $self->auth ? ( auth => $self->auth ) : ()
  );
}

=method for_realm

    my $dev = $kc->for_realm('dev');

The same client for another realm, sharing the user agent and the admin
login.

=cut

1;
```

- [ ] **Step 6: Tests laufen lassen**

Run: `prove -lr t/20-errors.t t/40-facade.t t/50-admin.t t/60-oidc.t` — Expected: PASS (3, 3, 7 und 6 Subtests). `t/20-errors.t` braucht dabei einen Moment, weil ein Subtest gegen einen geschlossenen Port läuft.

- [ ] **Step 7: Load-Test, Übergabe**

`  WWW::Keycloak::Admin` und `  WWW::Keycloak::OIDC` in die Liste in `t/00-load.t` (`WWW::Keycloak` steht schon drin), `prove -lr t` — Expected: PASS. Betreff: `Add OIDC, Admin API and the facade`; `Changes`: `- WWW::Keycloak facade with OIDC (discovery, verify_token, all grants, device flow steps) and the Admin REST API for realms, clients, client scopes, protocol mappers, users and authentication flows`.

---

### Task 4: `ensure_*`

Spec: Abschnitt 5.2.

**Files:**
- Modify: `lib/WWW/Keycloak/Admin.pm` (Abschnitt `ensure` vor dem schließenden `1;` einfügen)
- Test: `t/51-admin-ensure.t`

**Interfaces:**
- Consumes: Grundoperationen aus Aufgabe 3, `WWW::Keycloak::Diff->changes`.
- Produces: `ensure_realm(%rep)`, `ensure_client(%rep)`, `ensure_client_scope(%rep)`, `ensure_protocol_mapper( client => $clientId | client_scope => $name, %rep )`, `ensure_user(%rep)`, `ensure_execution_config( flow =>, authenticator =>, config =>, alias => )`, alle mit Rückgabe `{ id => ..., changed => 'created' | 'updated' | '' }`.

- [ ] **Step 1: Den Test schreiben**

`t/51-admin-ensure.t`:

```perl
#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use lib 't/lib';

use FakeKeycloak;
use WWW::Keycloak;

my $fake  = FakeKeycloak->new;
my $admin = WWW::Keycloak->new( base_url => $fake->base, realm => 'main', username => 'admin', password => 'admin', ua => $fake )->admin;

sub writes {
  my ( $code ) = @_;
  my $before = @{ $fake->requests };
  my $result = $code->();
  return ( $result, scalar grep { $_->method ne 'GET' && $_->uri->path !~ m{/token\z} } @{ $fake->requests }[ $before .. $#{ $fake->requests } ] );
}

subtest 'ensure_realm' => sub {
  my ( $r, $w ) = writes( sub { $admin->ensure_realm( enabled => \1, displayName => 'Main' ) } );
  is_deeply( $r, { id => 'main', changed => 'created' }, 'created' );
  ( $r, $w ) = writes( sub { $admin->ensure_realm( enabled => \1, displayName => 'Main' ) } );
  is( $r->{changed}, '', 'second run: nothing to do' );
  is( $w, 0, 'and nothing written' );
  ( $r, $w ) = writes( sub { $admin->ensure_realm( displayName => 'Main realm' ) } );
  is( $r->{changed}, 'updated', 'a change' );
  is( $w, 1, 'one write' );
  is( $fake->realm('main')->{rep}{enabled}, JSON::MaybeXS::true, 'other keys untouched' );
};

subtest 'ensure_client' => sub {
  my %want = ( clientId => 'cli', publicClient => \1, attributes => { 'oauth2.device.authorization.grant.enabled' => 'true' } );
  my $r = $admin->ensure_client(%want);
  is( $r->{changed}, 'created', 'created' );
  my ( $again, $w ) = writes( sub { $admin->ensure_client(%want) } );
  is_deeply( $again, { id => $r->{id}, changed => '' }, 'second run: same id, nothing to do' );
  is( $w, 0, 'nothing written' );
  my ( $changed ) = writes( sub { $admin->ensure_client( clientId => 'cli', attributes => { 'pkce.code.challenge.method' => 'S256' } ) } );
  is( $changed->{changed}, 'updated', 'an attribute added' );
  is_deeply(
    $fake->realm('main')->{clients}{ $r->{id} }{attributes},
    { 'oauth2.device.authorization.grant.enabled' => 'true', 'pkce.code.challenge.method' => 'S256' },
    'the other attribute kept'
  );
  ok( ${ $fake->realm('main')->{clients}{ $r->{id} }{publicClient} }, 'and the other keys too: the whole client was sent' );
  ok( !eval { $admin->ensure_client( publicClient => \1 ); 1 }, 'without clientId' );
  isa_ok( $@, 'WWW::Keycloak::Error::Validation' );
};

subtest 'ensure_client_scope and ensure_protocol_mapper' => sub {
  is( $admin->ensure_client_scope( name => 'amr' )->{changed}, 'created', 'scope created' );
  is( $fake->realm('main')->{scopes}{ $admin->find_client_scope('amr')->{id} }{protocol}, 'openid-connect', 'protocol defaults to openid-connect' );
  is( $admin->ensure_client_scope( name => 'amr' )->{changed}, '', 'scope: nothing to do' );
  is( $admin->ensure_client_scope( name => 'amr', description => 'd' )->{changed}, 'updated', 'scope updated' );

  my %mapper = ( name => 'amr', protocolMapper => 'oidc-amr-mapper', config => { 'id.token.claim' => 'true' } );
  is( $admin->ensure_protocol_mapper( client => 'cli', %mapper )->{changed}, 'created', 'mapper on a client, named by clientId' );
  is( $admin->ensure_protocol_mapper( client => 'cli', %mapper )->{changed}, '', 'nothing to do' );
  is( $admin->ensure_protocol_mapper( client => 'cli', name => 'amr', config => { 'access.token.claim' => 'true' } )->{changed}, 'updated', 'a config key added' );
  my ( $stored ) = values %{ $fake->realm('main')->{mappers}{ 'clients/'.$admin->find_client('cli')->{id} } };
  is_deeply( $stored->{config}, { 'id.token.claim' => 'true', 'access.token.claim' => 'true' }, 'merged' );
  is( $admin->ensure_protocol_mapper( client_scope => 'amr', %mapper )->{changed}, 'created', 'mapper on a scope, named by name' );
  ok( !eval { $admin->ensure_protocol_mapper( client => 'nope', %mapper ); 1 }, 'an unknown owner' );
  like( "$@", qr/no client nope/, 'is named' );
  ok( !eval { $admin->ensure_protocol_mapper( client => 'cli', protocolMapper => 'x' ); 1 }, 'without name' );
};

subtest 'ensure_user' => sub {
  my %want = ( username => 'Alice', email => 'Alice@Example.org', enabled => \1, credentials => [ { type => 'password', value => 'first', temporary => \0 } ] );
  my $r = $admin->ensure_user(%want);
  is( $r->{changed}, 'created', 'created' );
  my ( $again, $w ) = writes( sub { $admin->ensure_user( %want, credentials => [ { type => 'password', value => 'second' } ] ) } );
  is( $again->{changed}, '', 'second run, with other credentials and mixed case: nothing to do' );
  is( $w, 0, 'nothing written' );
  my ( $password ) = grep { $_->{type} eq 'password' } @{ $fake->realm('main')->{users}{ $r->{id} }{credentials} };
  is( $password->{value}, 'first', 'the password was not reset' );
  is( $admin->ensure_user( username => 'alice', firstName => 'Alice' )->{changed}, 'updated', 'a change' );
  is( $fake->realm('main')->{users}{ $r->{id} }{email}, 'alice@example.org', 'the rest kept' );
};

subtest 'ensure_execution_config' => sub {
  my %want = ( flow => 'browser', authenticator => 'auth-otp-form', config => { 'default.reference.value' => 'otp', 'default.reference.maxAge' => 3600 } );
  my $r = $admin->ensure_execution_config(%want);
  is( $r->{changed}, 'created', 'created' );
  my ( $execution ) = grep { ( $_->{providerId} // '' ) eq 'auth-otp-form' } @{ $fake->realm('main')->{flows}{browser} };
  is( $execution->{authenticationConfig}, $r->{id}, 'attached to the step' );
  is( $fake->realm('main')->{configs}{ $r->{id} }{alias}, 'browser auth-otp-form', 'default alias' );
  my $again = $admin->ensure_execution_config(%want);
  is_deeply( $again, { id => $r->{id}, changed => 'updated' }, 'Keycloak hides the values, so a second run writes again' );
  $admin->ensure_execution_config( %want, config => { 'default.reference.value' => 'otp' } );
  is_deeply( $fake->realm('main')->{configs}{ $r->{id} }{config}, { 'default.reference.value' => 'otp' }, 'replaced as given, never merged with masked values' );
  ok( !grep( { /\*{10}/ } values %{ $fake->realm('main')->{configs}{ $r->{id} }{config} } ), 'no masked value was written back' );
  is( $admin->ensure_execution_config( %want, flow => 'direct grant', authenticator => 'direct-grant-validate-otp', alias => 'mine' )->{changed}, 'created', 'in a flow with a space' );
  ok( !eval { $admin->ensure_execution_config( %want, authenticator => 'nope' ); 1 }, 'an unknown step' );
  like( "$@", qr/flow "browser" has no step nope/, 'is named' );
  ok( !eval { $admin->ensure_execution_config( flow => 'browser', authenticator => 'auth-otp-form' ); 1 }, 'without config' );
};

done_testing;
```

- [ ] **Step 2: Test laufen lassen, er muss scheitern**

Run: `prove -lr t/51-admin-ensure.t` — Expected: FAIL mit `Can't locate object method "ensure_realm" via package "WWW::Keycloak::Admin"`.

- [ ] **Step 3: Den Abschnitt `ensure` in `lib/WWW/Keycloak/Admin.pm` einfügen**

Direkt vor dem abschließenden `1;`:

```perl
####  ensure

sub _ensure {
  my ( $self, %arg ) = @_;
  my $current = $arg{find}->();
  return { id => $arg{create}->(), changed => 'created' } unless $current;
  my $changes = $self->diff_class->changes( $current, $arg{wanted} );
  return { id => $arg{id}->($current), changed => '' } unless %$changes;
  $arg{update}->( $current, $changes );
  return { id => $arg{id}->($current), changed => 'updated' };
}

sub ensure_realm {
  my ( $self, %rep ) = @_;
  return $self->_ensure(
    wanted => \%rep,
    find   => sub { my $realm = eval { $self->get_realm }; $self->_missing($@) unless $realm; $realm },
    create => sub { $self->create_realm( \%rep ) },
    update => sub { $self->update_realm( $_[1] ) },
    id     => sub { $_[0]->{realm} }
  );
}

=method ensure_realm

    $admin->ensure_realm( enabled => \1, accessTokenLifespan => 600 );

=cut

sub ensure_client {
  my ( $self, %rep ) = @_;
  WWW::Keycloak::Error::Validation->throw( message => 'ensure_client needs a clientId' ) unless defined $rep{clientId};
  return $self->_ensure(
    wanted => \%rep,
    find   => sub { $self->find_client( $rep{clientId} ) },
    create => sub { $self->create_client( \%rep ) },
    update => sub { $self->update_client( $_[0]{id}, { %{ $_[0] }, %{ $_[1] } } ) },
    id     => sub { $_[0]->{id} }
  );
}

=method ensure_client

    my $r = $admin->ensure_client( clientId => 'my-cli', publicClient => \1, attributes => { ... } );

=cut

sub ensure_client_scope {
  my ( $self, %rep ) = @_;
  WWW::Keycloak::Error::Validation->throw( message => 'ensure_client_scope needs a name' ) unless defined $rep{name};
  return $self->_ensure(
    wanted => \%rep,
    find   => sub { $self->find_client_scope( $rep{name} ) },
    create => sub { $self->create_client_scope( { protocol => 'openid-connect', %rep } ) },
    update => sub { $self->update_client_scope( $_[0]{id}, { %{ $_[0] }, %{ $_[1] } } ) },
    id     => sub { $_[0]->{id} }
  );
}

=method ensure_client_scope

    my $r = $admin->ensure_client_scope( name => 'amr', attributes => { 'include.in.token.scope' => 'false' } );

The protocol defaults to C<openid-connect>.

=cut

sub ensure_protocol_mapper {
  my ( $self, $kind, $owner_key, %rep ) = @_;
  WWW::Keycloak::Error::Validation->throw( message => 'ensure_protocol_mapper needs a name' ) unless defined $rep{name};
  my $owner = $kind && $kind eq 'client' ? $self->find_client($owner_key)
    : $kind && $kind eq 'client_scope' ? $self->find_client_scope($owner_key)
    : $self->_mapper_path($kind);
  WWW::Keycloak::Error::Validation->throw( message => 'ensure_protocol_mapper: no '.$kind.' '.$owner_key ) unless $owner;
  return $self->_ensure(
    wanted => \%rep,
    find   => sub { ( grep { $_->{name} eq $rep{name} } @{ $self->list_protocol_mappers( $kind, $owner->{id} ) } )[0] },
    create => sub { $self->create_protocol_mapper( $kind, $owner->{id}, { protocol => 'openid-connect', %rep } ) },
    update => sub { $self->update_protocol_mapper( $kind, $owner->{id}, $_[0]{id}, { %{ $_[0] }, %{ $_[1] } } ) },
    id     => sub { $_[0]->{id} }
  );
}

=method ensure_protocol_mapper

    my $r = $admin->ensure_protocol_mapper( client => 'my-cli', name => 'amr', protocolMapper => 'oidc-amr-mapper', config => { 'id.token.claim' => 'true' } );
    my $r = $admin->ensure_protocol_mapper( client_scope => 'amr', name => 'amr', ... );

The owner is named by C<clientId> or by scope name. The protocol defaults to
C<openid-connect>.

=cut

sub ensure_user {
  my ( $self, %rep ) = @_;
  WWW::Keycloak::Error::Validation->throw( message => 'ensure_user needs a username' ) unless defined $rep{username};
  # Keycloak keeps user names and e-mail addresses in lower case
  my %compare = %rep;
  delete $compare{credentials};
  $compare{$_} = lc $compare{$_} for grep { defined $compare{$_} } qw( username email );
  return $self->_ensure(
    wanted => \%compare,
    find   => sub { $self->find_user( $rep{username} ) },
    create => sub { $self->create_user( \%rep ) },
    update => sub { $self->update_user( $_[0]{id}, $_[1] ) },
    id     => sub { $_[0]->{id} }
  );
}

=method ensure_user

    my $r = $admin->ensure_user( username => 'alice', enabled => \1, email => 'alice@example.org',
      credentials => [ { type => 'password', value => $pw, temporary => \0 } ] );

C<credentials> are used when the user is created and ignored afterwards: a
password is not reset on every run. Call L</set_password> for that.
C<username> and C<email> are compared in lower case, the way Keycloak keeps
them.

=cut

sub ensure_execution_config {
  my ( $self, %arg ) = @_;
  for (qw( flow authenticator config )) {
    WWW::Keycloak::Error::Validation->throw( message => 'ensure_execution_config needs '.$_ ) unless defined $arg{$_};
  }
  my ( $execution ) = grep { ( $_->{providerId} // '' ) eq $arg{authenticator} } @{ $self->list_executions( $arg{flow} ) };
  WWW::Keycloak::Error::Validation->throw( message => 'flow "'.$arg{flow}.'" has no step '.$arg{authenticator} ) unless $execution;
  my $alias = $arg{alias} // $arg{flow}.' '.$arg{authenticator};
  return $self->_ensure(
    wanted => { config => $arg{config} },
    find   => sub { $execution->{authenticationConfig} ? $self->get_execution_config( $execution->{authenticationConfig} ) : undef },
    create => sub { $self->create_execution_config( $execution->{id}, { alias => $alias, config => $arg{config} } ) },
    update => sub { $self->update_execution_config( $_[0]{id}, { alias => $_[0]{alias}, config => $arg{config} } ) },
    id     => sub { $_[0]->{id} }
  );
}

=method ensure_execution_config

    my $r = $admin->ensure_execution_config(
      flow          => 'browser',
      authenticator => 'auth-otp-form',
      config        => { 'default.reference.value' => 'otp', 'default.reference.maxAge' => 3600 },
    );

Settings of one step of an authentication flow, found by its authenticator.
C<alias> names a new configuration; default C<< "<flow> <authenticator>" >>.

Give the complete configuration. Keycloak hides the values of these settings
when they are read (they come back as C<**********>), so they can neither be
compared nor merged: an existing configuration is replaced by C<config> and
reported as C<updated> on every run.

=cut

```

- [ ] **Step 4: Tests laufen lassen**

Run: `prove -lr t/51-admin-ensure.t` — Expected: PASS (5 Subtests). Dann `prove -lr t` — Expected: PASS.

- [ ] **Step 5: Übergabe**

Betreff: `Add ensure methods to the Admin API`; `Changes`: `- ensure_realm, ensure_client, ensure_client_scope, ensure_protocol_mapper, ensure_user, ensure_execution_config: repeatable setup that writes only what differs`.

---

### Task 5: Live-Suite, Wegwerf-Keycloak, README

Spec: Abschnitt 10. Braucht ein laufendes Keycloak für Schritt 3; Schritte 1, 2 und 4 gehen ohne.

**Files:**
- Create: `t/90-live-keycloak.t`, `t/keycloak/k8s.yaml`
- Modify: `README.md` (ganz ersetzen)

- [ ] **Step 1: Live-Suite und Manifest schreiben**

`t/90-live-keycloak.t`:

```perl
#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;

# Live test against a real Keycloak. Off unless KEYCLOAK_LIVE_TEST=1 and
# KEYCLOAK_URL point at one; KEYCLOAK_ADMIN and KEYCLOAK_ADMIN_PASSWORD are
# the bootstrap admin (default admin/admin). The test creates a realm with a
# random name, works only inside it, and deletes it at the end.

BEGIN {
  plan skip_all => 'set KEYCLOAK_LIVE_TEST=1 and KEYCLOAK_URL to run the Keycloak live test'
    unless $ENV{KEYCLOAK_LIVE_TEST} && $ENV{KEYCLOAK_URL};
}

use Crypt::JWT qw( decode_jwt );
use Digest::SHA qw( hmac_sha1 );
use WWW::Keycloak;

my $realm = 'wwwkc-live-'.join '', map { ( 'a' .. 'z' )[ rand 26 ] } 1 .. 8;
my $kc    = WWW::Keycloak->new(
  base_url => $ENV{KEYCLOAK_URL},
  realm    => $realm,
  username => $ENV{KEYCLOAK_ADMIN} // 'admin',
  password => $ENV{KEYCLOAK_ADMIN_PASSWORD} // 'admin'
);
my $admin = $kc->admin;
my $secret = '12345678901234567890';

# RFC 6238 with HMAC-SHA1, six digits
sub totp {
  my $step = int( time / 30 );
  my $mac  = hmac_sha1( pack( 'NN', int( $step / 4294967296 ), $step % 4294967296 ), $secret );
  my $off  = ord( substr $mac, -1 ) & 0x0f;
  return sprintf '%06d', ( unpack( 'N', substr $mac, $off, 4 ) & 0x7fffffff ) % 1_000_000;
}

sub twice {
  my ( $name, $code ) = @_;
  my $first  = $code->();
  my $second = $code->();
  is( $first->{changed}, 'created', $name.': created' );
  is( $second->{changed}, '', $name.': second run changes nothing' );
  is( $second->{id}, $first->{id}, $name.': same id' );
  return $first;
}

END { eval { $admin->delete_realm } if $admin }

subtest 'server' => sub {
  my $info = $admin->server_info;
  diag 'Keycloak '.$info->{systemInfo}{version};
  ok( grep( { $_->{id} eq 'oidc-amr-mapper' } @{ $info->{protocolMapperTypes}{'openid-connect'} } ), 'offers the AMR mapper' );
};

subtest 'a realm from nothing, twice' => sub {
  twice( realm => sub { $admin->ensure_realm( enabled => \1, displayName => 'WWW::Keycloak live test' ) } );
  is( $admin->ensure_realm( accessTokenLifespan => 600 )->{changed}, 'updated', 'a realm setting changed' );
  is( $admin->get_realm->{displayName}, 'WWW::Keycloak live test', 'the others kept' );

  twice( client => sub {
    $admin->ensure_client(
      clientId                  => 'live-cli',
      publicClient              => \1,
      standardFlowEnabled       => \0,
      directAccessGrantsEnabled => \1,
      attributes                => { 'oauth2.device.authorization.grant.enabled' => 'true' }
    );
  } );
  is( $admin->ensure_client( clientId => 'live-cli', description => 'changed' )->{changed}, 'updated', 'client changed' );
  is( $admin->find_client('live-cli')->{attributes}{'oauth2.device.authorization.grant.enabled'}, 'true', 'the attribute kept' );

  twice( mapper => sub {
    $admin->ensure_protocol_mapper( client => 'live-cli', name => 'amr', protocolMapper => 'oidc-amr-mapper',
      config => { 'id.token.claim' => 'true', 'access.token.claim' => 'true' } );
  } );
  twice( scope => sub { $admin->ensure_client_scope( name => 'live-scope', description => 'x' ) } );
  twice( user => sub {
    $admin->ensure_user(
      username      => 'Live-User',
      email         => 'Live@Example.org',
      firstName     => 'Live',
      lastName      => 'User',
      enabled       => \1,
      emailVerified => \1,
      credentials   => [
        { type => 'password', value => 'live-password', temporary => \0 },
        { type => 'otp', secretData => '{"value":"'.$secret.'"}',
          credentialData => '{"subType":"totp","digits":6,"counter":0,"period":30,"algorithm":"HmacSHA1"}' }
      ]
    );
  } );
  is_deeply( [ sort map { $_->{type} } @{ $admin->list_credentials( $admin->find_user('live-user')->{id} ) } ], [qw( otp password )], 'password and OTP set at creation' );

  for my $step ( [ 'direct grant', 'direct-grant-validate-password', 'pwd' ], [ 'direct grant', 'direct-grant-validate-otp', 'otp' ] ) {
    my %arg = ( flow => $step->[0], authenticator => $step->[1], config => { 'default.reference.value' => $step->[2], 'default.reference.maxAge' => 3600 } );
    is( $admin->ensure_execution_config(%arg)->{changed}, 'created', $step->[1].': created' );
    is( $admin->ensure_execution_config(%arg)->{changed}, 'updated', $step->[1].': written again, Keycloak hides the values' );
  }
};

subtest 'OIDC against the new realm' => sub {
  my $oidc   = $kc->oidc;
  my $tokens = $oidc->password_token( client_id => 'live-cli', username => 'live-user', password => 'live-password', totp => totp(), scope => 'openid' );
  ok( $tokens->{access_token}, 'a login with password and TOTP' );
  my $claims = $oidc->verify_token( $tokens->{id_token}, audience => 'live-cli' );
  is( $claims->{preferred_username}, 'live-user', 'verify_token' );
  is_deeply( $claims->{amr}, [qw( pwd otp )], 'amr reports both steps' );
  is( $oidc->userinfo( $tokens->{access_token} )->{preferred_username}, 'live-user', 'userinfo' );
  ok( $oidc->refresh_token( $tokens->{refresh_token}, client_id => 'live-cli' )->{access_token}, 'refresh_token' );

  my $wrong = eval { $oidc->password_token( client_id => 'live-cli', username => 'live-user', password => 'live-password' ); 1 } ? undef : $@;
  is( $wrong && $wrong->oauth_error, 'invalid_grant', 'without the TOTP code: invalid_grant' );

  my $start = $oidc->device_authorization( client_id => 'live-cli', scope => 'openid' );
  like( $start->{verification_uri_complete}, qr/\Q$start->{user_code}\E/, 'device_authorization' );
  my $pending = eval { $oidc->device_token( device_code => $start->{device_code}, client_id => 'live-cli' ); 1 } ? undef : $@;
  is( $pending && $pending->oauth_error, 'authorization_pending', 'device_token before approval' );

  ok( $oidc->logout( refresh_token => $tokens->{refresh_token}, client_id => 'live-cli' ), 'logout' );
  my $after = eval { $oidc->refresh_token( $tokens->{refresh_token}, client_id => 'live-cli' ); 1 } ? undef : $@;
  is( $after && $after->oauth_error, 'invalid_grant', 'the refresh token is dead after logout' );
};

subtest 'clean up' => sub {
  ok( $admin->delete_realm, 'realm deleted' );
  my $gone = eval { $admin->get_realm; 1 } ? undef : $@;
  ok( $gone && $gone->is_not_found, 'and gone' );
  undef $admin;
};

done_testing;
```

`t/keycloak/k8s.yaml`:

```yaml
# Throwaway Keycloak for t/90-live-keycloak.t. No persistence: start-dev with
# the embedded database. The test makes and removes its own realm.
#
#   kubectl create namespace keycloak-test
#   kubectl -n keycloak-test apply -f t/keycloak/k8s.yaml
#   kubectl -n keycloak-test rollout status deploy/keycloak
#   kubectl -n keycloak-test get svc keycloak        # the NodePort is the port of KEYCLOAK_URL
#   kubectl delete namespace keycloak-test
#
# The image needs a CPU with x86-64-v2; on a VM with a generic CPU model the
# pod dies with "Fatal glibc error: CPU does not support x86-64-v2".
apiVersion: apps/v1
kind: Deployment
metadata:
  name: keycloak
  labels:
    app: keycloak
spec:
  replicas: 1
  selector:
    matchLabels:
      app: keycloak
  template:
    metadata:
      labels:
        app: keycloak
    spec:
      containers:
        - name: keycloak
          image: quay.io/keycloak/keycloak:26.8.0
          args: ["start-dev"]
          env:
            - name: KC_BOOTSTRAP_ADMIN_USERNAME
              value: admin
            - name: KC_BOOTSTRAP_ADMIN_PASSWORD
              value: admin
          ports:
            - name: http
              containerPort: 8080
          readinessProbe:
            httpGet:
              path: /realms/master
              port: http
            initialDelaySeconds: 20
            periodSeconds: 5
            failureThreshold: 60
          resources:
            requests:
              cpu: 250m
              memory: 768Mi
            limits:
              memory: 2Gi
---
apiVersion: v1
kind: Service
metadata:
  name: keycloak
spec:
  type: NodePort
  selector:
    app: keycloak
  ports:
    - name: http
      port: 8080
      targetPort: http
```

Run: `prove -lr t/90-live-keycloak.t` — Expected: `skipped: set KEYCLOAK_LIVE_TEST=1 and KEYCLOAK_URL to run the Keycloak live test`.

- [ ] **Step 2: `README.md` ersetzen**

`README.md`:

````markdown
# WWW-Keycloak

Perl client for [Keycloak](https://www.keycloak.org/): OpenID Connect against a
realm, and the Admin REST API to bring a realm into a wanted state from Perl,
repeatably.

```perl
use WWW::Keycloak;

my $kc = WWW::Keycloak->new(
  base_url => 'https://id.example.org',
  realm    => 'main',
  username => 'admin',            # or client_id + client_secret, or token
  password => $ENV{KEYCLOAK_ADMIN_PASSWORD},
);

# OpenID Connect
my $claims = $kc->oidc->verify_token( $jwt, audience => 'my-api' );
my $tokens = $kc->oidc->password_token( client_id => 'cli', username => 'alice', password => $pw, totp => $code );

# Admin REST API: wanted state, as often as you like
my $admin = $kc->admin;
$admin->ensure_client( clientId => 'cli', publicClient => \1,
  attributes => { 'oauth2.device.authorization.grant.enabled' => 'true' } );
$admin->ensure_protocol_mapper( client => 'cli', name => 'amr', protocolMapper => 'oidc-amr-mapper',
  config => { 'id.token.claim' => 'true', 'access.token.claim' => 'true' } );
$admin->ensure_user( username => 'alice', enabled => \1,
  credentials => [ { type => 'password', value => $pw, temporary => \0 } ] );
$admin->ensure_execution_config( flow => 'browser', authenticator => 'auth-otp-form',
  config => { 'default.reference.value' => 'otp', 'default.reference.maxAge' => 3600 } );
```

Every `ensure_*` method looks the object up by its readable key, creates it
when it is missing, otherwise writes only what differs, and returns
`{ id => ..., changed => 'created' | 'updated' | '' }`. Nothing is deleted.

The admin login is managed: the token is fetched on first use, renewed before
it runs out, and renewed once more when Keycloak refuses it (as after a
restart).

Developed and live-tested against Keycloak 26.8.0. The async twin is
`Net::Async::Keycloak`.

## Live tests

```bash
KEYCLOAK_LIVE_TEST=1 KEYCLOAK_URL=http://localhost:8080 prove -lv t/90-live-keycloak.t
```

The test creates a realm with a random name and deletes it again. A throwaway
Keycloak on Kubernetes: `t/keycloak/k8s.yaml`.

## License

This library is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.
````

- [ ] **Step 3: Gegen ein echtes Keycloak laufen lassen**

Wenn keines läuft: nach den Kommentaren in `t/keycloak/k8s.yaml` starten.
Run: `KEYCLOAK_LIVE_TEST=1 KEYCLOAK_URL=http://<node>:<nodeport> prove -lv t/90-live-keycloak.t`
Expected: PASS (4 Subtests), `diag` nennt die Keycloak-Version. Der Test löscht seinen Realm am Ende, auch wenn er scheitert (`END`-Block). Wenn er abbricht, bevor `$admin` existiert, bleibt nichts zurück.

- [ ] **Step 4: Alles laufen lassen, Übergabe**

Run: `prove -lr t && dzil test` — Expected: beide PASS. Betreff: `Add live suite, Kubernetes manifest and README`; `Changes`: `- Live tests against a real Keycloak behind KEYCLOAK_LIVE_TEST`.
