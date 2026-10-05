# WWW::Authentik – Design

Datum: 2026-10-04
Status: freigegeben am 2026-10-04; die Entscheidungen aus Abschnitt 11 sind getroffen.
Distribution: `WWW-Authentik` (Repo `p5-www-authentik`), CPAN-fähig, `[@Author::GETTY]`
Zwilling: `Net-Async-Authentik` (Repo `p5-net-async-authentik`), folgt diesem Design mit `_f`-Methoden.
Vorbild: `WWW-Keycloak` (`docs/superpowers/specs/2026-10-02-www-keycloak-design.md` dort); Form und Namen folgen ihm, der Code wird kopiert und angepasst, nicht geteilt.

## 1. Was WWW::Authentik ist

**WWW::Authentik ist der Perl-Client für authentik: OIDC gegen eine Application und die
REST-API v3, mit der man ein authentik aus Perl heraus in einen gewünschten Zustand
bringt.**

Der Anlass ist derselbe wie bei Keycloak: Airlock soll neben `Airlock::Upstream::Keycloak`
ein `Airlock::Upstream::Authentik` bekommen und braucht dafür ein authentik, das sich für
Tests wiederholbar einrichten lässt (Application, Provider, Nutzer mit Passwort und TOTP), und
Gewissheit, was das Token über den zweiten Faktor sagt. Mit dieser Dist soll das so aussehen:

```perl
my $ak = WWW::Authentik->new(
  base_url    => 'http://127.0.0.1:9000',
  application => 'airlock-test',
  token       => $ENV{AUTHENTIK_TOKEN},
);

my $provider = $ak->api->ensure_oauth2_provider(
  name               => 'airlock-test',
  authorization_flow => 'default-provider-authorization-implicit-consent',
  invalidation_flow  => 'default-provider-invalidation-flow',
  client_type        => 'confidential',
  grant_types        => [qw( authorization_code refresh_token urn:ietf:params:oauth:grant-type:device_code )],
  redirect_uris      => [ { matching_mode => 'strict', url => 'http://127.0.0.1:1/cb' } ],
  scopes             => [qw( openid email profile offline_access )],
);
$ak->api->ensure_application( slug => 'airlock-test', name => 'Airlock Test', provider => 'airlock-test' );

my $claims = $ak->oidc->verify_token($jwt);   # $claims->{amr} = ['pwd', 'mfa']
```

### Was WWW::Authentik nicht ist

- **Kein Deployment-Werkzeug.** authentik starten, PostgreSQL, Worker, Zertifikate gehören
  dem Betreiber. Diese Dist redet mit einem authentik, das schon läuft.
- **Kein Ersatz für Blueprints.** Was sich als YAML-Blueprint beschreiben lässt und nie
  wieder aus Perl heraus angefasst wird, darf ein Blueprint bleiben (Abschnitt 11, Punkt 4).
- **Kein Browser.** Der Flow-Executor ist eine JSON-API, und die Live-Tests benutzen ihn
  für den Login (Abschnitt 8.3). Eine öffentliche Klasse dafür ist Phase 2 (Abschnitt 11,
  Punkt 7), nicht Teil von Phase 1.
- **Keine vollständige Abdeckung der API v3.** Die API hat 607 Pfade. Phase 1 nimmt, was ein
  OIDC-Setup und ein Nutzer mit zweitem Faktor brauchen; Policies, Sources, Outposts, SAML,
  LDAP, RBAC-Rollen und Events kommen, wenn sie gebraucht werden.

## 2. Aufbau

```
WWW::Authentik                    Fassade: base_url, application (Slug), token, ua
  ├─ ->oidc    WWW::Authentik::OIDC       Discovery, JWKS, Token prüfen, Token holen
  ├─ ->api     WWW::Authentik::API        REST-API v3, direkte Methoden und ensure_*
  └─ ->for_application('x')              dieselbe Fassade für eine andere Application

WWW::Authentik::Diff              Vergleich ohne I/O, von beiden Dists benutzt
WWW::Authentik::Role::HTTP        build_request / read_response / send_request
WWW::Authentik::Error             ::Validation, ::Network, ::API (ein Paket pro Datei)
```

Moo, eine Klasse pro Belang, eine gemeinsame `LWP::UserAgent`-Instanz (über `ua`
injizierbar), direkte Methoden statt verschachtelter Sub-Clients (`$api->list_users`, nicht
`$api->users->list`).

Vier Dinge sind bei authentik anders als bei Keycloak und prägen den Aufbau:

1. **Es gibt keinen Realm.** Die API liegt für die ganze Instanz unter `<base_url>/api/v3/`.
   OIDC ist je *Application* adressiert: Discovery, JWKS und End-Session liegen unter
   `<base_url>/application/o/<slug>/`, Authorize, Token, Userinfo, Introspect, Revoke und
   Device sind instanzweit unter `<base_url>/application/o/`. Der Application-Slug ist deshalb
   ein optionales Attribut der Fassade: ohne ihn gibt es `api`, mit ihm auch `oidc`.
2. **Das API-Token lebt lange.** Ein API-Token (`intent: api`, `expiring: false`) läuft nicht
   ab. Es gibt nichts zu erneuern; eine `Auth`-Klasse wie bei Keycloak entfällt
   (Abschnitt 4, Abschnitt 11 Punkt 3).
3. **Doppelte Objekte sind 400, nicht 409.** Ein zweites Anlegen beantwortet authentik mit
   `400 {"slug": ["Application with this slug already exists."]}`, also einem Feldfehler
   wie jeder andere Validierungsfehler. `ensure_*` muss vorher suchen und darf sich nicht auf
   einen Konflikt-Status verlassen (Abschnitt 7).
4. **Objekte hängen anders zusammen.** Eine Application hat höchstens einen Provider
   (`provider`, Integer-PK) und wird im Pfad über den Slug angesprochen; ein Provider hat eine
   eindeutige `name`, Flows als UUID und Property-Mappings als UUID-Liste; Flows haben Slug im
   Pfad, UUID in Referenzen; Stages haben je Typ einen eigenen Endpunkt; Bindings sind
   eigene Objekte (Flow, Stage, `order`). Die sprechenden Schlüssel, über die `ensure_*`
   sucht, stehen in Abschnitt 5.2.

## 3. Fassade

```perl
my $ak = WWW::Authentik->new(
  base_url    => 'https://id.example.org',   # Pflicht, ohne /api/v3
  application => 'my-app',                   # optional, Slug; nötig für ->oidc
  token       => $api_token,                 # optional; nötig für ->api
  ua          => $lwp,                       # optional
);

$ak->oidc;                       # WWW::Authentik::OIDC für 'my-app'
$ak->api;                        # WWW::Authentik::API
$ak->issuer;                     # https://id.example.org/application/o/my-app/
$ak->for_application('other');   # Fassade für eine andere Application, gleiche ua, gleiches Token
```

`base_url` leer: `WWW::Authentik::Error::Validation`. Ein abschließender `/` wird entfernt.
`oidc` ohne `application` und `api` ohne `token` werfen beim ersten Zugriff eine
Validation-Exception. Die Standard-`ua` folgt keinen Redirects (wie bei Keycloak; der
Authorize-Endpunkt antwortet mit 302, dessen `Location` der Aufrufer oder das Executor-Hilfsmodul der Tests liest).

## 4. Anmeldung an der API

Jeder Aufruf der API trägt `Authorization: Bearer <token>`. Drei Quellen für das Token, alle
beobachtet:

| Quelle | Lebensdauer | Beobachtet |
|---|---|---|
| Bootstrap-Token (`AUTHENTIK_BOOTSTRAP_TOKEN`) | `expiring: false` | gelistet als `authentik-bootstrap-token`, `intent: api`, Nutzer `akadmin` |
| Über die API angelegtes Token (`POST /core/tokens/`, `intent: api`, `expiring: false`) | unbegrenzt | Schlüssel per `view_key`, eigener Wert per `set_key` |
| OIDC-Access-Token mit Scope `goauthentik.io/api` | `expires_in` 300 | Client-Credentials-Token als Bearer gegen `/core/users/me/` 200; Rechte sind die des Service-Accounts (Liste der Nutzer: 403) |

Phase 1 kennt nur ein festes `token`. Es wird nicht erneuert; ein ungültiges oder
abgelaufenes Token beantwortet authentik mit `403 {"detail": "Token invalid/expired"}`, ein
fehlendes mit `403 {"detail": "Authentication credentials were not provided."}`. Beides wird
zu `WWW::Authentik::Error::API` mit `is_forbidden` (Abschnitt 7). Ohne Anmeldung
funktioniert `oidc`.

Das Token erscheint in keiner Exception und in keinem Log.

## 5. API (`WWW::Authentik::API`)

### 5.1 Grundoperationen

Jede Methode ist ein dünner Aufruf eines Endpunkts unter `<base_url>/api/v3`. Pfade enden auf
`/`; ohne Schrägstrich antwortet authentik 404. Rückgaben: `get_*` und `find_*` liefern die
Repräsentation als Hash (oder nichts bei `find_*` ohne Treffer), `list_*` eine Array-Referenz
mit allen Treffern (die Methode folgt `pagination.next`, bis `0` kommt), `create_*` die
Repräsentation des neuen Objekts (authentik antwortet `201` mit dem ganzen Objekt, ohne
`Location`-Header), `update_*` die neue Repräsentation, `delete_*` wahr.

Listen kommen als `{"pagination": {"next", "previous", "count", "current", "total_pages",
"start_index", "end_index"}, "results": [...]}`, `next` ist `0` auf der letzten Seite.
`page_size` ist ein Query-Parameter; eine Seite jenseits der letzten ist `404 {"detail":
"Invalid page."}`. Filter sind exakte Gleichheit (`?username=probe-alice` findet
`probe-alice`, `?username=probe` nichts), `?search=` sucht unscharf, `?ordering=` sortiert.

`update_*` schickt `PATCH`. authentiks `PUT` verlangt die Pflichtfelder, lässt nicht
genannte Felder aber stehen (beobachtet an Nutzer, Gruppe, Application; der Provider
verlangt `redirect_uris`), ist also kein Ersetzen. Da `PATCH` dasselbe ohne Pflichtfelder
tut, gibt es keinen Grund für `PUT`. `attributes` (Nutzer, Gruppe) werden bei `PATCH` als
Ganzes ersetzt, nicht zusammengeführt; `ensure_*` führt sie vor dem Schreiben selbst zusammen.

| Bereich | Methoden |
|---|---|
| Instanz | `version` (`/admin/version/`), `config` (`/root/config/`), `settings` (`/admin/settings/`), `me` (`/core/users/me/`) |
| Applications | `list_applications(%query)`, `find_application($slug)`, `create_application(\%rep)`, `update_application($slug, \%changes)`, `delete_application($slug)`, `check_access($slug, for_user => $pk)` |
| OAuth2-Provider | `list_oauth2_providers(%query)`, `find_oauth2_provider($name)`, `get_oauth2_provider($pk)`, `create_oauth2_provider(\%rep)`, `update_oauth2_provider($pk, \%changes)`, `delete_oauth2_provider($pk)`, `provider_setup_urls($pk)`, `preview_user($pk, $user_pk)` |
| Scope-Mappings | `list_scope_mappings(%query)`, `find_scope_mapping($name)`, `find_scope_mappings_by_scope(@scope_names)`, `create_scope_mapping(\%rep)`, `update_scope_mapping($uuid, \%changes)`, `delete_scope_mapping($uuid)`, `test_property_mapping($uuid, user => $pk)` |
| Nutzer | `list_users(%query)`, `find_user($username)`, `get_user($pk)`, `create_user(\%rep)`, `update_user($pk, \%changes)`, `delete_user($pk)`, `set_password($pk, $password)`, `create_service_account(name => $n, %opt)`, `list_authenticators($pk)` |
| Gruppen | `list_groups(%query)`, `find_group($name)`, `get_group($uuid)`, `create_group(\%rep)`, `update_group($uuid, \%changes)`, `delete_group($uuid)`, `add_user_to_group($uuid, $user_pk)`, `remove_user_from_group($uuid, $user_pk)` |
| Tokens | `list_tokens(%query)`, `get_token($identifier)`, `create_token(\%rep)`, `update_token($identifier, \%changes)`, `delete_token($identifier)`, `view_token_key($identifier)`, `set_token_key($identifier, $key)` |
| Flows | `list_flows(%query)`, `find_flow($slug)`, `create_flow(\%rep)`, `update_flow($slug, \%changes)`, `delete_flow($slug)`, `export_flow($slug)` (YAML als String) |
| Stages | `list_stages(%query)` (`/stages/all/`), `stage_types`, `get_stage($type, $uuid)`, `create_stage($type, \%rep)`, `update_stage($type, $uuid, \%changes)`, `delete_stage($type, $uuid)` |
| Bindings | `list_bindings(flow => $slug)`, `create_binding(\%rep)`, `update_binding($uuid, \%changes)`, `delete_binding($uuid)` |
| Brand | `list_brands`, `current_brand`, `update_brand($uuid, \%changes)` |
| Zertifikate | `list_certificates(%query)`, `find_certificate($name)` |
| Blueprints | `list_blueprints`, `create_blueprint(\%rep)`, `apply_blueprint($uuid)`, `get_blueprint($uuid)`, `delete_blueprint($uuid)` |
| Roh | `call($method, $path, \%body)` für jeden Endpunkt ohne eigene Methode |

`$type` bei Stages ist der Pfadteil hinter `/stages/`: `password`, `identification`,
`user_login`, `authenticator/validate`, `authenticator/totp`, `consent`, `prompt`, …
(`stage_types` liefert `component` und `model_name` aller 25 Typen). `/stages/all/` kann nur
lesen; `PATCH` dort ist 405.

`find_user` sucht mit `?username=` exakt und groß/klein-unterscheidend; authentik erlaubt
`Probe-Bob` und `probe-bob` nebeneinander. `find_application` ist `GET /core/applications/<slug>/`
und fängt die 404.

`create_service_account` ist `POST /core/users/service_account/`: authentik legt Nutzer und
ein App-Password-Token an und gibt das Token genau einmal zurück (`{username, user_pk,
user_uid, token}`). Dieses Token ist das `password` für `client_credentials` mit
`username` (Abschnitt 6).

### 5.2 `ensure_*`: gewünschter Zustand statt Einzelschritt

Wie bei Keycloak: suchen, anlegen oder abgleichen, sagen, was getan wurde.

```perl
my $r = $api->ensure_user( username => 'alice', name => 'Alice', attributes => { dept => 'x' } );
$r->{object};    # die Repräsentation nach dem Lauf
$r->{changed};   # 'created', 'updated' oder ''
```

Statt `id` gibt `ensure_*` das ganze Objekt zurück, weil authentik keine einheitliche
Kennung hat (Slug, Integer-PK, UUID, Identifier) und ein Aufrufer meist den nächsten Schlüssel
braucht (den Provider-PK für die Application, die Flow-UUID für die Binding).

| Methode | Schlüssel, über den gesucht wird | Auflösung sprechender Namen |
|---|---|---|
| `ensure_application(%rep)` | `slug` | `provider => $name` → Provider-PK |
| `ensure_oauth2_provider(%rep)` | `name` | `authorization_flow`, `invalidation_flow`, `authentication_flow => $slug` → UUID; `signing_key => $name` → UUID; `scopes => [@scope_names]` → `property_mappings` |
| `ensure_scope_mapping(%rep)` | `name` | – |
| `ensure_user(%rep)` | `username` | `groups => [@names]` → UUIDs |
| `ensure_group(%rep)` | `name` | – |
| `ensure_token(%rep)` | `identifier` | `user => $username` → PK |
| `ensure_flow(%rep)` | `slug` | – |
| `ensure_stage($type, %rep)` | `name` (eindeutig über alle Stage-Typen) | `configure_flow => $slug` → UUID |
| `ensure_binding(flow => $slug, stage => $name, order => $n, %rep)` | Flow und Stage | beide → UUID |

Regeln, die für alle gelten:

- **Abgeglichen wird nur, was angegeben ist.** Schlüssel, die der Aufrufer nicht nennt,
  bleiben. `attributes` werden schlüsselweise zusammengeführt und dann als Ganzes gesendet,
  weil `PATCH` sie ersetzt.
- **Erst vergleichen, dann schreiben.** Stimmt der Zustand, gibt es keinen schreibenden
  Aufruf und `changed` ist leer.
- **Listen sind Mengen.** `property_mappings` kommen in anderer Reihenfolge zurück als
  gesendet; `grant_types` und `redirect_uris` behalten die Reihenfolge, haben aber keine
  Bedeutung darin. `Diff` vergleicht jede Liste als Menge, auch Listen von Hashes
  (kanonisches JSON je Element). Bindings mit ihrer Reihenfolge sind eigene Objekte mit
  einem Feld `order`, keine Liste.
- **Defaults, die authentik ergänzt, ergänzt `Diff` vor dem Vergleich.** `redirect_uris`
  kommen mit `redirect_uri_type: "authorization"` zurück, auch wenn es nicht gesendet wurde.
  Das ist in Phase 1 der einzige beobachtete Fall; die Liste steht in `Diff` an einer Stelle.
- **`ensure_user` fasst das Passwort nur beim Anlegen an.** `password` ist kein Feld des
  Nutzers; `ensure_user` ruft nach dem Anlegen `set_password`, danach nie wieder. Wer das
  will, ruft `set_password`. `set_password` nimmt jedes Passwort an (`204`, auch für `"a"`),
  Passwort-Policies gelten nur in Flows.
- **`ensure_oauth2_provider` verlangt `grant_types` beim Anlegen.** Ein über die API ohne
  `grant_types` angelegter Provider hat `grant_types: []` und beantwortet jede Token-Anfrage
  mit `invalid_grant` (Log: „Invalid grant_type for provider“). Weil die Dist nicht raten
  soll, welche Grants gemeint sind, ist das Fehlen beim Anlegen ein Validation-Fehler
  (Abschnitt 11, Punkt 5).
- **`ensure_token` kann kein Ablaufdatum setzen.** `expires` wird beim Anlegen und bei
  `PATCH` ignoriert und auf jetzt plus `default_token_duration` (`days=1`) gesetzt; nur
  `expiring` ist steuerbar. `ensure_token` vergleicht `expires` nicht und wirft bei
  gegebenem `expires` einen Validation-Fehler.
- **Nichts wird gelöscht.** `ensure_*` entfernt keine Objekte und keine Schlüssel.
  Das Löschen einer Stage löscht ihre Bindings (`DELETE` auf die Stage: Bindings danach 0).

### 5.3 Was anders zurückkommt als geschrieben

Beobachtet, und für `Diff` festgehalten:

- `client_secret` kommt im Klartext zurück und lässt sich setzen; es ist vergleichbar.
  authentik erzeugt auch für `client_type: public` ein Secret (128 Zeichen).
- Lesefelder (`pk`, `uid`, `component`, `assigned_application_slug`, `*_obj`, …) werden beim
  Schreiben still ignoriert, unbekannte Felder ebenso. Eine gelesene Repräsentation lässt
  sich unverändert zurückschreiben (`PUT` mit dem `GET`-Body: 200 an Nutzer, Application,
  Provider, Mapping, Flow, Stage, Gruppe, Brand).
- Nutzer: `path` Standard `users`, `type` Standard `internal`, `attributes` beliebig
  verschachtelt (Zahlen, Booleans, Listen, Hashes bleiben typisiert).
- Provider: `access_token_validity` u. ä. sind Strings wie `minutes=5`, `days=30`;
  `grant_types` nimmt nur die acht Werte der `GrantTypeEnum`
  (`authorization_code`, `implicit`, `hybrid`, `refresh_token`, `client_credentials`,
  `password`, `urn:ietf:params:oauth:grant-type:device_code`,
  `urn:ietf:params:oauth:grant-type:token-exchange`); ein falscher Wert ist
  `400 {"grant_types": {"0": ["\"x\" is not a valid choice."]}}`.
- Scope-Mapping: `expression` wird beim Anlegen kompiliert; ein Syntaxfehler ist
  `400 {"expression": ["Expression Syntax Error: …"]}`. `scope_name` ist nicht eindeutig,
  `name` ist es.
- Stage-`name` ist über alle Stage-Typen eindeutig (`400 {"name": ["stage with this name
  already exists."]}` auch für einen anderen Typ).
- Binding: `(target, stage, order)` ist eindeutig (`400 {"non_field_errors": ["The fields
  target, stage, order must make a unique set."]}`); dieselbe Stage mit anderer `order`
  lässt sich ein zweites Mal binden.
- Ein Provider gehört zu höchstens einer Application (`400 {"provider": ["Application with
  this provider already exists."]}`).

## 6. OIDC (`WWW::Authentik::OIDC`)

Wie `WWW::Keycloak::OIDC`, mit den authentik-Eigenheiten:

| Methode | Zweck |
|---|---|
| `discovery`, `jwks`, `*_endpoint` | Metadaten, mit Cache; `jwks(force_refresh => 1)` |
| `issuer` | aus dem Discovery-Dokument, nicht berechnet (Abschnitt 6.1) |
| `verify_token($jwt, audience => ..., type => 'access' \| 'id')` | Signatur, `iss`, `exp`, optional `aud` und Tokenart |
| `userinfo($access_token)`, `introspect($token, client_id =>, client_secret =>)`, `revoke($token, client_id =>, client_secret =>)` | |
| `client_credentials_token(client_id =>, client_secret =>, scope =>)` | Grant für den vom Provider automatisch angelegten Service-Account `ak-<provider>-client_credentials` |
| `client_credentials_token(client_id =>, client_secret =>, username =>, password =>, scope =>)` | Grant für einen eigenen Service-Account mit App-Password-Token |
| `refresh_token($refresh_token, client_id =>, client_secret =>)` | Refresh-Token werden rotiert; das alte ist danach `invalid_grant` |
| `exchange_authorization_code(code =>, redirect_uri =>, client_id =>, client_secret =>)` | |
| `device_authorization(client_id =>, scope =>)`, `device_token(device_code =>, client_id =>, client_secret =>)` | ein Schritt des Device-Flows; die Poll-Schleife ist Sache des Aufrufers |
| `authorization_url(%param)` | nur den URL bauen; der Browser ist nicht Teil der Dist |

Kein `password_token` für Endnutzer: authentiks `grant_type=password` ist derselbe Weg wie
`client_credentials` mit `username`/`password` eines Service-Accounts und gibt für einen
normalen Nutzer `invalid_grant` (beobachtet). Wer für Tests ein Nutzer-Token braucht, geht
über den Flow-Executor (Abschnitt 8.3).

Der Token-Endpunkt nimmt die Client-Anmeldung als `client_secret_post` und
`client_secret_basic` (beide beobachtet). Alle Werte werden form-kodiert gesendet; der
`device_code` enthält Anführungszeichen, `%` und `&` und ist ohne Kodierung `invalid_grant`.

### 6.1 Issuer und Tokenart

Mit `issuer_mode: per_provider` (Standard) ist `iss` =
`<base_url>/application/o/<slug>/`, mit `issuer_mode: global` ist es `<base_url>/`; JWKS und
End-Session bleiben in beiden Fällen unter dem Slug. `verify_token` prüft deshalb gegen das
`issuer` des Discovery-Dokuments, das immer unter dem Slug liegt.

ID- und Access-Token sind beide `RS256`-JWTs mit `"typ": "JWT"` im Header; die Tokenart steht
nicht im Header. Das Access-Token trägt zusätzlich `azp`, `scope` und `uid`, das ID-Token
`nonce` (wenn angefragt) und nach einem Refresh `at_hash`. `type => 'access'` verlangt
`scope`, `type => 'id'` verbietet es. `verify_token` akzeptiert nur `RS*`, `PS*`, `ES*`;
authentik meldet `id_token_signing_alg_values_supported: ["RS256"]`.

### 6.2 Zweiter Faktor im Token

Beobachtet an authentik 2026.8.3 mit der Standard-Konfiguration (`default-authentication-flow`
mit Identification, Password, Authenticator Validation (`not_configured_action: skip`),
User Login), ohne jede Änderung an Flow, Stage oder Mapping:

| Login | `amr` | `acr` | `auth_time` |
|---|---|---|---|
| Passwort | `["pwd"]` | `goauthentik.io/providers/oauth2/default` | Zeitpunkt des Logins |
| Passwort + TOTP | `["pwd", "mfa"]` | `goauthentik.io/providers/oauth2/default` | Zeitpunkt des Logins |
| Client Credentials | fehlt | `goauthentik.io/providers/oauth2/default` | = `iat` |

`amr`, `acr` und `auth_time` stehen gleich in ID-Token, Access-Token und Introspection-Antwort,
und `auth_time` bleibt über Refresh und über weitere Authorize-Aufrufe derselben Sitzung
erhalten (eine zweite Autorisierung 4 Minuten nach dem Login trug noch das alte `auth_time`).
`amr` bleibt nach dem Refresh. `acr` ist konstant; `acr_values` und `max_age=0` im
Authorize-Aufruf ändern nichts und erzwingen keinen neuen Login (beide beobachtet, Code kam
sofort). Es gibt kein Mapping und keine Stage-Einstellung, die dafür nötig wäre; Discovery
nennt `claims_supported: [..., "auth_time", "acr", "amr", ...]`.

Für `Airlock::Upstream::Authentik` heißt das: `mfa` in `amr` ist das Signal für den zweiten
Faktor; `acr` taugt nicht zur Unterscheidung.

**Erzwungenes TOTP** (beobachtet 2026-10-04, Nachtrag aus Abschnitt 12). Wer den zweiten
Faktor verlangen will, stellt `not_configured_action` an der Validation-Stage um:

```perl
$api->ensure_stage( 'authenticator/validate',
  name                 => 'default-authentication-mfa-validation',
  not_configured_action => 'deny',
);
```

| Einstellung | Nutzer ohne Authenticator | Nutzer mit TOTP |
|---|---|---|
| `skip` (Standard) | Login geht durch, `amr: ["pwd"]` | Code verlangt, `amr: ["pwd","mfa"]` |
| `deny` | `200 {"component":"ak-stage-access-denied","error_message":"No (allowed) MFA authenticator configured."}`, keine Sitzung | unverändert `amr: ["pwd","mfa"]` |
| `configure` (braucht `configuration_stages`) | der Setup-Stage wird eingeschoben: `200 {"component":"ak-stage-authenticator-totp","config_url":"otpauth://…"}` | unverändert |

`configure` ohne `configuration_stages` lehnt authentik ab:
`400 {"not_configured_action":["When \"Not configured action\" is set to \"Configure\", you
must set a configuration stage."]}`. Beide Felder müssen in **einem** `PATCH` kommen; das tut
`ensure_stage` ohnehin, weil es alle abweichenden Schlüssel zusammen schickt.

`deny` ändert an `amr`, `acr` und `auth_time` eines erfolgreichen Logins nichts: Dieselben
Werte wie bei `skip`. Der Unterschied ist allein, ob ein Nutzer ohne zweiten Faktor
hereinkommt.

## 7. Fehler

Ein Paket pro Datei, wie bei Keycloak:

- `WWW::Authentik::Error` — Basis mit `message`, stringifiziert zu ihr.
- `WWW::Authentik::Error::Validation` — falsche Argumente, fehlende Zugangsdaten, abgelehnte Tokens.
- `WWW::Authentik::Error::Network` — keine Antwort.
- `WWW::Authentik::Error::API` — HTTP 4xx/5xx, mit `http_status`, `api_message`, `field_errors`
  (Hash, kann leer sein), `oauth_error`, `request_id` und den Prädikaten `is_not_found` (404),
  `is_forbidden` (403), `is_bad_request` (400), `is_unauthorized` (401).

authentik hat vier Fehlerformen, alle beobachtet:

| Form | Beispiel | Woher |
|---|---|---|
| `{"detail": "…"}` | `403 {"detail": "Token invalid/expired"}`, `404 {"detail": "No User matches the given query."}`, `405 {"detail": "Method \"PATCH\" not allowed."}`, `400 {"detail": "JSON parse error - …"}`, `415 {"detail": "Unsupported media type …"}` | API, kein Feldbezug |
| `{"<feld>": ["…"], "non_field_errors": ["…"]}` | `400 {"username": ["This field must be unique."]}`, `400 {"name": ["This field is required."], "slug": [...]}` | API, Validierung; verschachtelt bei `grant_types` (`{"grant_types": {"0": [...]}}`) und beim Transaktions-Endpunkt (`{"app": {"slug": [...]}}`) |
| `{"error": "…", "error_description": "…", "request_id": "…"}` | `400 invalid_grant`, `400 invalid_client`, `400 unsupported_grant_type`, `400 invalid_scope`, `400 authorization_pending`, `401 invalid_client` (Revoke mit falschem Secret) | Token-, Device-, Revoke-Endpunkt |
| leerer Body, `WWW-Authenticate: error="invalid_token", error_description="…"` | `401` | Userinfo |

`api_message` ist `detail`, sonst die Feldfehler zu einer Zeile verbunden
(`username: This field must be unique.`), sonst `error: error_description`. `is_conflict` gibt
es nicht: ein Duplikat ist nicht von einem anderen Validierungsfehler zu unterscheiden, außer
am Text. Ein 500 kommt ohne Body (beobachtet an `POST /authenticators/admin/totp/`).

## 8. Am laufenden authentik beobachtet

authentik 2026.8.3 (`ghcr.io/goauthentik/server:2026.8.3`, PostgreSQL 16), 2026-10-04,
Wegwerf-Instanz per Docker Compose auf `127.0.0.1:9000`, Bootstrap-Admin `akadmin`.
Jede Zeile ist ein tatsächlich abgesetzter Aufruf. Pfade in 8.1 relativ zu
`<base_url>/api/v3`, in 8.2 zu `<base_url>`.

### 8.1 API v3

| Aufruf | Antwort |
|---|---|
| beliebiger Aufruf ohne Token / mit ungültigem Token | 403 `{"detail":"Authentication credentials were not provided."}` / 403 `{"detail":"Token invalid/expired"}` |
| `GET /admin/version/`, `GET /root/config/`, `GET /admin/settings/`, `GET /core/users/me/` | 200; `version_current: "2026.8.3"`; `default_token_duration: "days=1"` |
| `GET /core/users/?page_size=1` | 200; `pagination` mit `next: 2`, `count`, `total_pages`; dazu ein `autocomplete`-Block |
| `GET /core/users/?page=99` | 404 `{"detail":"Invalid page."}` |
| `GET /core/users/?username=probe-alice` / `?username=probe` / `?username=PROBE-ALICE` / `?search=alice` | 200; 1 / 0 / 0 / 1 Treffer |
| `POST /core/users/` (`username`, `name`, `email`, `attributes`, `path`, `type`) | 201, ganzes Objekt mit `pk` (Integer), `uuid`, `uid`; kein `Location` |
| `POST /core/users/` zweites Mal | 400 `{"username":["This field must be unique."]}` |
| `POST /core/users/` mit `Probe-Bob` nach `probe-bob` | 201; beide existieren |
| `GET /core/users/{pk}/`, `GET /core/users/999999/` | 200 / 404 `{"detail":"No User matches the given query."}` |
| `PATCH /core/users/{pk}/` (`attributes`) | 200; `attributes` als Ganzes ersetzt (`{"one","two"}` → `{"three"}`); typisierte Werte bleiben |
| `PATCH /core/users/{pk}/` mit `uid`, `pk`, unbekanntem Feld | 200; still ignoriert |
| `PUT /core/users/{pk}/` nur `username` | 400 `{"name":["This field is required."]}` |
| `PUT /core/users/{pk}/` `username`+`name` | 200; `email`, `path`, `attributes`, `groups` bleiben |
| `PUT /core/users/{pk}/` mit dem `GET`-Body | 200 |
| `POST /core/users/{pk}/set_password/` `{"password": …}` | 204, auch für `"a"` |
| `POST /core/users/{pk}/recovery/` | 400 `{"non_field_errors":"No recovery flow set."}` |
| `POST /core/users/service_account/` `{"name","create_group":false}` | 200 `{"username","user_uid","user_pk","token"}`; Nutzer `type: service_account`, `path: goauthentik.io/service-accounts` |
| `DELETE /core/users/{pk}/` zweimal | 204 / 404 |
| `GET /core/groups/?name=x`, `POST /core/groups/` | 200 / 201 (`pk` UUID, `num_pk`, `users`, `users_obj`, `parents`, `children`); zweites Mal 400 `{"name":["Group with this name already exists."]}` |
| `PATCH` / `PUT /core/groups/{uuid}/` | 200 / 200; `PUT` mit nur `name` lässt `attributes` stehen |
| `POST /core/groups/{uuid}/add_user/` `{"pk": N}`, `…/remove_user/` | 204 / 204, `remove_user` auch für Nicht-Mitglied 204 |
| `PATCH /core/users/{pk}/` `{"groups": [uuid]}` | 200; Mitgliedschaft auch von der Nutzerseite setzbar |
| `DELETE /core/groups/{uuid}/` zweimal | 204 / 404 |
| `GET /core/tokens/` | 200; `authentik-bootstrap-token` mit `intent: api`, `expiring: false` |
| `POST /core/tokens/` (`identifier`, `intent: api`, `expiring: false`) | 201; zweites Mal 400 `{"identifier":["Token with this identifier already exists."]}` |
| `POST /core/tokens/` mit `expires` +3 s; `PATCH` mit `expires` +2 h | 201 / 200; `expires` beide Male jetzt + 1 Tag |
| `GET /core/tokens/{id}/view_key/`, `POST …/set_key/` `{"key": …}` | 200 `{"key"}` / 204; der gesetzte Schlüssel ist sofort als Bearer gültig |
| `POST /core/tokens/` `intent: app_password` | 201; `view_key` 60 Zeichen |
| `PATCH` / `PUT /core/tokens/{id}/`, `DELETE` zweimal | 200 / 200 / 204 / 404 |
| `GET /core/applications/`, `POST /core/applications/` (`name`, `slug`, ohne `provider`) | 200 / 201 (`pk` = `pbm_uuid`, `provider: null`, `launch_url`, `meta_*`, `policy_engine_mode: any`) |
| `POST /core/applications/` zweites Mal | 400 `{"slug":["Application with this slug already exists."]}`; gleicher `name` mit anderem Slug 201 |
| `POST /core/applications/` `{}` / `slug: "Bad Slug!"` | 400 `{"name":[…],"slug":[…]}` / 400 `{"slug":["Enter a valid “slug” …"]}` |
| `GET /core/applications/{slug}/`, `?slug=x` / `?slug=teil` | 200 / 1 / 0 Treffer |
| `PATCH /core/applications/{slug}/` (`meta_description`, `provider: N`, `slug` umbenennen) | 200; nach dem Umbenennen alter Slug 404 |
| `POST /core/applications/` mit schon vergebenem `provider` | 400 `{"provider":["Application with this provider already exists."]}` |
| `GET /core/applications/{slug}/check_access/` | 200 `{"passing":true,"messages":[],"log_messages":[]}` |
| `DELETE /core/applications/{slug}/` unbekannt | 404 |
| `PUT /core/transactional/applications/` (`app`, `provider_model`, `provider`) | 200 `{"applied":true,"logs":[]}`; zweites Mal 400 `{"app":{"slug":[…already exists.]}}` – nicht wiederholbar |
| `GET /providers/oauth2/`, `POST /providers/oauth2/` `{"name"}` | 200 / 400 `{"authorization_flow":[required],"invalidation_flow":[required],"redirect_uris":[required]}` |
| `POST /providers/oauth2/` vollständig | 201; `pk` Integer, `client_id` 40 Zeichen, `client_secret` 128 Zeichen im Klartext, `grant_types: []`, `redirect_uris[*].redirect_uri_type: "authorization"` ergänzt, `property_mappings` umsortiert |
| `POST /providers/oauth2/` zweites Mal | 400 `{"name":["provider with this name already exists."], …}` |
| `GET /providers/oauth2/?name=x` / `?name=teil` / `?search=teil` | 1 / 0 / 1 Treffer |
| `PATCH /providers/oauth2/{pk}/` `redirect_uris` umgekehrt / `client_secret` / `grant_types` / `issuer_mode` | 200; Reihenfolge der `redirect_uris` und `grant_types` bleibt; `grant_types: ["device_code"]` 400 `{"3":["\"device_code\" is not a valid choice."]}` |
| `PUT /providers/oauth2/{pk}/` ohne `redirect_uris` / mit `GET`-Body | 400 / 200 |
| `GET /providers/oauth2/{pk}/setup_urls/` vor / nach Zuordnung zur Application | 200 `issuer: null` / 200 mit `issuer`, `provider_info`, `jwks`, `logout`, `dcr_registration` |
| `GET /providers/oauth2/{pk}/preview_user/?for_user=N` | 200 `{"preview": {iss, sub, aud, acr, auth_time, email, …}}` |
| `GET /providers/oauth2/{pk}/used_by/`, `GET /providers/all/` | 200 |
| `DELETE /providers/oauth2/{pk}/` | 204 |
| `GET /propertymappings/provider/scope/` | 200; 9 Default-Mappings mit `managed: goauthentik.io/providers/oauth2/scope-<name>` (dazu eines des Proxy-Providers), `scope_name`, `expression` |
| `POST /propertymappings/provider/scope/` (`name`, `scope_name`, `expression`) | 201 (`pk` UUID, `managed: null`); gleicher `name` 400 `{"name":["Property Mapping with this name already exists."]}`; gleicher `scope_name` 201 |
| `POST …/scope/` mit `expression: "return {"` | 400 `{"expression":["Expression Syntax Error: …"]}` |
| `GET …/scope/?name=x` / `?scope_name=x` / `?managed=…` | 200 |
| `PATCH` / `PUT …/scope/{uuid}/`, `DELETE` | 200 / 200 / 204 |
| `POST /propertymappings/all/{uuid}/test/` `{"user": N}` | 200 `{"result":"{\"probe\": true}","successful":true}` |
| `GET /propertymappings/all/types/`, `GET /propertymappings/all/?managed__isnull=true` | 200 |
| `GET /flows/instances/` | 200; 15 Default-Flows mit `slug`, `designation`, `authentication`, `stages` (UUIDs) |
| `POST /flows/instances/` (`name`, `slug`, `title`, `designation`) | 201 (`pk` UUID, `stages: []`, `layout: stacked`, `denied_action: message_continue`); zweites Mal 400 `{"slug":["Flow with this slug already exists."]}` |
| `PATCH` / `PUT /flows/instances/{slug}/`, `PUT` mit `GET`-Body | 200 |
| `GET /flows/instances/{slug}/export/` | 200, `content-type: text/html`, Body YAML (`version`, `entries`) |
| `DELETE /flows/instances/{slug}/` zweimal | 204 / 404 |
| `GET /stages/all/types/`, `GET /stages/all/`, `GET /stages/all/?name=x`, `GET /stages/all/{uuid}/` | 200; 25 Typen; `{uuid}` liefert nur `pk`, `name`, `component`, `verbose_name`, `meta_model_name`, `flow_set`, keine typisierten Felder |
| `PATCH /stages/all/{uuid}/` | 405 |
| `POST /stages/password/` (`name`, `backends`) | 201; gleicher `name` 400 `{"name":["stage with this name already exists."]}`, auch an `/stages/user_login/` |
| `PATCH` / `PUT /stages/password/{uuid}/` | 200; `backends`-Reihenfolge bleibt |
| `GET /stages/authenticator/validate/`, `/stages/password/`, `/stages/identification/`, `/stages/authenticator/totp/`, `/stages/user_login/` | 200, typisierte Felder (`not_configured_action: skip`, `device_classes`, `last_auth_threshold`, `backends`, `user_fields`, `digits`, `session_duration`) |
| `PATCH /stages/authenticator/validate/{uuid}/` `{"not_configured_action":"deny"}` | 200 |
| dasselbe mit `"configure"` ohne `configuration_stages` / mit beiden Feldern in einem `PATCH` | 400 `{"not_configured_action":["When \"Not configured action\" is set to \"Configure\", you must set a configuration stage."]}` / 200 |
| `PUT /stages/authenticator/validate/{uuid}/` mit `GET`-Body | 200 |
| `DELETE /stages/password/{uuid}/` mit Binding | 204; Binding danach weg |
| `GET /flows/bindings/?target=<slug>` / `?target=<uuid>` | 400 `{"target":["… is not a valid UUID."]}` / 200 mit `order`, `stage`, `stage_obj`, `evaluate_on_plan`, `re_evaluate_policies` |
| `POST /flows/bindings/` (`target`, `stage`, `order`) | 201; gleiche drei 400 `{"non_field_errors":["The fields target, stage, order must make a unique set."]}`; andere `order` 201 |
| `PATCH` / `PUT /flows/bindings/{uuid}/`, `DELETE` | 200 / 200 / 204 |
| `GET /policies/bindings/` | 200 (`target`, `policy`, `group`, `user`, `order`, `enabled`) |
| `GET /core/brands/`, `PATCH /core/brands/{uuid}/` `{"flow_device_code": uuid}`, `PUT` mit `GET`-Body | 200 / 200 / 200 |
| `GET /crypto/certificatekeypairs/` | 200; `authentik Self-signed Certificate`, `private_key_available: true` |
| `GET /managed/blueprints/`, `GET …/available/` | 200; 31 Instanzen, 45 Dateien |
| `POST /managed/blueprints/` mit `content` (Inline-YAML, Gruppe `state: present`) | 201 `status: unknown` |
| `POST /managed/blueprints/{uuid}/apply/` | 200, `status` noch `unknown`; 3 s später `successful`, `last_applied`, Gruppe vorhanden; zweites `apply` ändert nichts, Gruppe weiter genau einmal |
| `POST /managed/blueprints/` mit unbekanntem Model | 400 `{"content":["Failed to validate blueprint","- App or Model does not exist",…]}` |
| `GET /oauth2/access_tokens/`, `GET /oauth2/refresh_tokens/` | 200; `scope` als Liste, `revoked`, `expires`, `id_token`; das Token selbst wird nicht ausgegeben |
| `GET /authenticators/admin/totp/?user=N`, `GET /authenticators/admin/all/?user=N` | 200 |
| `POST /authenticators/admin/totp/` `{"name"}` | 500, leerer Body (`IntegrityError: null value in column "user_id"`) |
| `POST /core/groups/` als Formular statt JSON / mit kaputtem JSON | 415 / 400 `{"detail":"JSON parse error - …"}` |
| `GET /core/users` ohne Schrägstrich | 404 |
| `OPTIONS /core/users/{pk}/` | `allow: GET, PUT, PATCH, DELETE, HEAD, OPTIONS` |

### 8.2 OIDC

| Aufruf | Antwort |
|---|---|
| `GET /application/o/{slug}/.well-known/openid-configuration` | 200; `issuer` mit Slug, `device_authorization_endpoint`, `introspection_endpoint`, `revocation_endpoint`, `end_session_endpoint` mit Slug, `grant_types_supported` folgt den `grant_types` des Providers, `acr_values_supported: ["goauthentik.io/providers/oauth2/default"]`, `claims_supported` mit `amr`, `acr`, `auth_time` |
| Discovery für unbekannten Slug / Application ohne Provider | 404 / 404 |
| `GET /application/o/{slug}/jwks/` | 200; ein RSA-Schlüssel mit `kid`, `x5c` |
| `POST /application/o/token/` `client_credentials` an Provider mit `grant_types: []` | 400 `invalid_grant` |
| `POST /application/o/token/` `client_credentials` + `client_secret` | 200 `{access_token, id_token, token_type, scope, expires_in: 300}`; Nutzer `ak-<provider>-client_credentials` wird angelegt (`type: service_account`, `path: goauthentik.io/apps/<slug>`) |
| dasselbe mit `-u client_id:client_secret` (Basic) | 200 |
| `client_credentials` + `username`/`password` (Service-Account, App-Password-Token) | 200; `sub` des Service-Accounts |
| `grant_type=password` mit Service-Account / mit normalem Nutzer | 200 / 400 `invalid_grant` |
| falsches Secret / unbekannter Client / `grant_type=banana` / Refresh-Token `garbage` / Code `garbage` | 400 `invalid_grant` / 400 `invalid_client` / 400 `unsupported_grant_type` / 400 `invalid_grant` / 400 `invalid_grant` |
| `GET /application/o/authorize/?response_type=code…` ohne Sitzung | 302 nach `/if/flow/default-authentication-flow/?…&next=…` |
| dasselbe mit Sitzung (implicit consent) | 302 `https://app.example.org/cb?code=…&state=…` |
| dasselbe mit `max_age=0` / `acr_values=…` | 302 mit Code, kein neuer Login |
| `POST /application/o/token/` `authorization_code` | 200 `{access_token, id_token, refresh_token, scope, token_type, expires_in}`; `refresh_token` 128 Zeichen, kein JWT; Code zweites Mal 400 `invalid_grant` |
| `GET /application/o/userinfo/` Bearer / `POST` mit `access_token` | 200 / 200 `{sub, email, name, preferred_username, groups, nonce}` |
| Userinfo mit ungültigem Token | 401, leerer Body, `WWW-Authenticate: error="invalid_token"` |
| `POST /application/o/introspect/` Access-Token / Refresh-Token / ID-Token | 200 `{active: true, scope, client_id, amr, acr, auth_time, …}` / 200 `active: true` / 200 `{"active":false}` |
| Introspect mit falschem Secret | 200 `{"active":false}` (kein 401) |
| `POST /application/o/token/` `refresh_token` | 200, neues Refresh-Token; das alte danach 400 `invalid_grant`; `scope=openid` als Teilmenge 400 `invalid_scope`; das alte Access-Token bleibt bis `exp` gültig |
| `POST /application/o/revoke/` Access-Token / zweites Mal / `garbage` / falsches Secret | 200 `{}` / 200 / 200 / 401 `invalid_client` |
| Introspect / Userinfo nach Revoke | `{"active":false}` / 401 |
| `POST /application/o/device/` `client_id`, `scope` | 200 `{device_code (128 Zeichen), user_code (9 Ziffern), verification_uri: <base_url>/device, verification_uri_complete: <base_url>/device?code=<user_code>, expires_in: 60, interval: 5}`; unbekannter Client 400 `invalid_client` |
| `POST /application/o/token/` `device_code` vor Bestätigung / sofort noch einmal / nach Bestätigung / danach / nach 60 s | 400 `authorization_pending` / 400 `authorization_pending` (kein `slow_down`) / 200 mit `amr: ["pwd"]` / 400 `invalid_grant` / 400 `invalid_grant` |
| `GET /device?code=…` ohne / mit Sitzung | 302 `/flows/-/default/authentication/?next=…` / 302 `/if/flow/default-provider-authorization-implicit-consent/?code=…` |
| `GET /application/o/{slug}/end-session/` mit Sitzung | 302 `/if/flow/default-provider-invalidation-flow/`; die Sitzung lebt, bis der Flow ausgeführt ist |

### 8.3 Login über die Flow-Executor-API

Der Browser-Login ist eine JSON-API und ließ sich vollständig per HTTP fahren. Cookie-Jar
nötig (`authentik_session`, `authentik_csrf`); der CSRF-Wert geht als Header
`X-authentik-CSRF` mit. Jede Antwort `302` heißt „nächste Stage“: ihr `Location` ist
dieselbe Executor-Adresse, die man dann mit `GET` holt.

```
GET  /api/v3/flows/executor/default-authentication-flow/?query=
     200 {"component":"ak-stage-identification", "user_fields":["email","username"], …}
POST …  {"component":"ak-stage-identification","uid_field":"probe-alice"}
     302 → GET: 200 {"component":"ak-stage-password","pending_user":"probe-alice"}
POST …  {"component":"ak-stage-password","password":"…"}
     302 → GET: 302 → GET: 200 {"component":"xak-flow-redirect","to":"/","final_redirect":true}
GET  /api/v3/core/users/me/ (mit Cookies)   200 {"user":{"username":"probe-alice"}}
```

Mit eingerichtetem TOTP kommt nach dem Passwort statt der zweiten 302:

```
     200 {"component":"ak-stage-authenticator-validate",
          "device_challenges":[{"device_class":"totp","device_uid":"2","challenge":{}}]}
POST …  {"component":"ak-stage-authenticator-validate","code":"123456",
         "selected_challenge":{"device_class":"totp","device_uid":"2","challenge":{},"last_used":null}}
     302 → GET: 200 {"component":"xak-flow-redirect", …}
```

Ein falsches Passwort ist `200` mit demselben `component` und
`response_errors: {"password":[{"string":"Invalid password","code":"invalid"}]}`; die Stage
wird wiederholt. Danach liefert `GET /application/o/authorize/?…` mit den Cookies direkt die
302 mit dem Code; der Authorization-Flow (implicit consent) läuft ohne weiteren Executor-Schritt.

TOTP einrichten ging nur über den Setup-Flow, der Admin-Endpunkt ist kaputt (8.1):

```
GET  /api/v3/flows/executor/default-authenticator-totp-setup/?query=   (mit Login-Cookies)
     200 {"component":"ak-stage-authenticator-totp",
          "config_url":"otpauth://totp/authentik%3Aprobe-alice?secret=<Base32>&algorithm=SHA1&digits=6&period=30&issuer=authentik"}
POST …  {"component":"ak-stage-authenticator-totp","code":"<TOTP aus secret>"}
     200 {"component":"xak-flow-redirect", …}
```

Danach listet `GET /api/v3/authenticators/admin/totp/?user=<pk>` das Gerät. Beim nächsten
Login verlangt die Standard-Validation-Stage den Code (Abschnitt 6.2).

Mit `not_configured_action: deny` endet der Login eines Nutzers ohne Authenticator nach der
Passwort-Stage:

```
POST …  {"component":"ak-stage-password","password":"…"}
     302 → GET: 200 {"component":"ak-stage-access-denied","pending_user":"probe-dave",
                     "error_message":"No (allowed) MFA authenticator configured."}
GET  /api/v3/core/users/me/ (mit Cookies)   200 {"user":{"username":null}}
```

Mit `configure` und dem TOTP-Setup-Stage in `configuration_stages` kommt stattdessen der
Setup-Stage mitten im Login (`200 {"component":"ak-stage-authenticator-totp","config_url":…}`),
und die Sitzung entsteht erst, nachdem er abgeschlossen ist. Ein Nutzer, der TOTP schon hat,
merkt von beiden Einstellungen nichts.

Für den Device-Flow braucht die Brand ein `flow_device_code`; gesetzt wurde ein leerer Flow
mit `designation: stage_configuration`. Mit Login-Cookies führt `GET /device?code=<user_code>`
auf `/if/flow/default-provider-authorization-implicit-consent/?code=…`; der Executor dafür
antwortet `200 {"component":"ak-provider-oauth2-device-code-finish"}`, und der nächste Poll
liefert die Tokens.

### 8.4 Nicht beobachtet

Deshalb im Plan vor dem Bauen zu prüfen:

- Der Device-Flow **ohne** `flow_device_code` an der Brand (`device_authorization` antwortet
  auch dann 200; was `GET /device?code=` dann tut, wurde nicht geprüft).
- `slow_down` und `expired_token` am Device-Endpunkt: der Poll nach Ablauf war
  `invalid_grant`, ein zu schneller Poll `authorization_pending`.
- `last_auth_threshold` an der Validation-Stage; WebAuthn, Static Tokens, Duo, SMS, E-Mail
  als zweiter Faktor und das `amr` dafür. (`not_configured_action: deny|configure` ist
  inzwischen beobachtet, siehe 6.2 und 8.3.)
- Explicit-Consent-Flow (`default-provider-authorization-explicit-consent`) per Executor,
  PKCE (`code_challenge`), `response_mode=form_post`, `id_token_hint` und
  `post_logout_redirect_uri` am End-Session-Endpunkt, Backchannel-Logout.
- `issuer_mode: global` nur am Discovery-Dokument, nicht am Token.
- Eigene Scope-Mappings im Token (ein Mapping wurde angelegt und mit `test` geprüft, aber
  nicht an den Provider gehängt); `sub_mode` außer `hashed_user_id`; `encryption_key`.
- `PUT /core/transactional/applications/` als Aktualisierung: schlug mit „slug already exists“
  fehl, ein Update-Modus wurde nicht gefunden.
- Blueprints, die vorhandene Objekte ändern oder `state: absent` tragen; ob ein von einem
  Blueprint angelegtes Objekt sich gegen `PATCH` wehrt (die Gruppe trug kein `managed`-Feld).
- RBAC: Rollen, Berechtigungen eines Nicht-Superuser-Tokens (der Service-Account bekam 403
  auf `/core/users/`).
- Policies und Policy-Bindings schreibend; Sources; Outposts; SAML, LDAP, Proxy-Provider.
- `/core/users/{pk}/set_password_hash/`, `impersonate`, `account_lockdown`.
- `page_size`-Obergrenze (1000 wurde angenommen, die Instanz hatte 6 Nutzer).
- Verhalten älterer Versionen (2025.x) und der Enterprise-Funktionen.

## 9. Zwilling

`Net::Async::Authentik` spiegelt die öffentliche API mit `_f`-Suffix und Futures, nach dem
Muster von `Net::Async::Keycloak`: gleiche Klassen, gleiche Methoden, gleiche
Fehlerhierarchie. Diese Dist führt; der Zwilling folgt je Phase und hängt von `WWW-Authentik`
ab für `WWW::Authentik::Role::HTTP` (`build_request`, `read_response`) und
`WWW::Authentik::Diff`. Alles mit I/O wird im Zwilling eigenständig geschrieben.

Zwei Dinge sind beim Zwilling aufwendiger als bei Keycloak und gehören von Anfang an ins
Design der Sync-Dist, damit beide gleich bleiben:

- **Paginierung.** `list_*` folgt `pagination.next`. Die Schleife liegt in einer Methode
  `_paged($path, %query)`, die im Zwilling als `_paged_f` mit `repeat` nachgebaut wird;
  die Grenzfälle (`next: 0`, leeres `results`) stehen in `Diff`-freien Unit-Tests beider Dists.
- **Namensauflösung in `ensure_*`.** `ensure_oauth2_provider` löst Flows, Zertifikat und
  Scopes auf, bevor es vergleicht. Diese Auflösung ist eine eigene Methode `_resolve(\%rep)`
  mit einer Tabelle (Feld → Nachschlagemethode), damit der Zwilling dieselbe Tabelle
  benutzt und nur die Aufrufe asynchron macht.

## 10. Tests und Phasen

- **Unit-Tests** mit gemocktem HTTP nach dem Muster von `p5-www-keycloak/t/50-admin.t` und
  `t/60-oidc.t`: jede Methode gegen die in Abschnitt 8 beobachteten Antworten, darunter die
  vier Fehlerformen, die Paginierung über drei Seiten, 403 statt 401, 400 statt 409.
- **`WWW::Authentik::Diff`** rein, ohne HTTP: Listen als Mengen (auch von Hashes), ergänzte
  Defaults (`redirect_uri_type`), `attributes` zusammenführen, Booleans, nichts zu tun.
- **Live-Suite** (`t/90-live-authentik.t`, nur mit `AUTHENTIK_LIVE_TEST=1 AUTHENTIK_URL=…
  AUTHENTIK_TOKEN=…`): legt Nutzer, Gruppe, Scope-Mapping, Provider, Application, Flow,
  Stage, Binding und Token mit zufälligem Präfix an, fährt jede `ensure_*`-Methode zweimal
  (erst `created`, dann leer), prüft OIDC gegen die Application (Discovery, JWKS,
  Client-Credentials, Introspect, Revoke, Device-Authorization bis `authorization_pending`),
  loggt den Nutzer per Flow-Executor ein (Hilfsmodul in `t/lib`), prüft `amr: ["pwd"]`,
  richtet TOTP ein, loggt erneut ein und prüft `amr: ["pwd","mfa"]`, und löscht alles wieder.
  Das Compose-File der Wegwerf-Instanz liegt in `t/authentik/` (ohne Geheimnisse; `.env` nach
  `t/authentik/env.example`).

| Phase | Inhalt |
|---|---|
| 1 | Fassade, Fehler, `Role::HTTP`, `API`-Grundoperationen aus 5.1, `ensure_*` aus 5.2, `Diff`, `OIDC`, Unit-Tests, Live-Suite, Executor-Hilfsmodul in `t/lib`. Erster Nutzer: Airlocks Testaufbau für `Airlock::Upstream::Authentik`. |
| 2 | `WWW::Authentik::Flow` (Executor als öffentliche Klasse, Abschnitt 11 Punkt 7), Blueprint-Anwendung mit Warten auf `status`, Policies und Policy-Bindings, Nicht-Superuser-Tokens (RBAC) |
| 3 | Sources, Outposts, Proxy-Provider, SAML, Events |

Der Zwilling zieht nach jeder Phase nach.

Abhängigkeiten: `Moo`, `LWP::UserAgent`, `HTTP::Message`, `JSON::MaybeXS`, `Crypt::JWT`,
`URI`, `Type::Tiny`, `namespace::autoclean`; HTTPS über `LWP::Protocol::https`. Nichts aus
`WWW-Keycloak`.

## 11. Entscheidungen (getroffen 2026-10-04, jeweils wie vorgeschlagen)

1. **Name des API-Subclients: `api` oder `admin`?** authentik nennt es „API“; es gibt keine
   getrennte Admin-API, derselbe Endpunkt dient Selbstbedienung und Verwaltung, das Token
   entscheidet über die Rechte. `admin` wäre gleich zu `WWW::Keycloak->admin` und für
   Umsteiger vertraut, aber eine Benennung, die authentik nicht kennt. **Vorschlag: `api`**,
   Klasse `WWW::Authentik::API`. Das Skeleton (`CLAUDE.md`, `www-authentik-core`, die
   Agent-Definitionen) nennt noch `Admin` und ist nach der Entscheidung anzupassen.
2. **Welche Objekte gehören in Phase 1?** Die Tabelle in 5.1 ist der Vorschlag: alles, was
   das Airlock-Setup (Provider, Application, Nutzer mit Passwort und TOTP, Device-Flow über
   die Brand) und die Live-Suite brauchen, plus Gruppen und Tokens, weil sie beobachtet sind
   und trivial. Stages nur über die typisierten Endpunkte mit `$type`-Parameter, keine
   Methode je Stage-Typ. Blueprints nur die fünf dünnen Aufrufe, ohne Warten auf `status`
   (Phase 2). **Vorschlag: so.**
3. **Braucht es `WWW::Authentik::Auth`?** Nein. Das API-Token läuft nicht ab, authentik
   lehnt es mit 403 ab, und es gibt nichts zu erneuern. Der dritte Weg aus Abschnitt 4
   (OIDC-Token mit Scope `goauthentik.io/api`) wäre der einzige Grund, und er bringt in Phase 1
   nichts: Der automatisch angelegte Service-Account hat keine Rechte, und Rechte vergeben
   heißt RBAC (Phase 2). **Vorschlag: keine `Auth`-Klasse; `token` ist ein String.** Wer in
   Phase 2 OIDC-Tokens für die API will, bekommt einen `token`-Coderef oder eine kleine
   Klasse, die `OIDC->client_credentials_token` mit Ablauf kapselt; die Fassade bleibt gleich.
4. **Wie verhält sich `ensure_*` zu Blueprints?** Blueprints sind authentiks eigener
   deklarativer, wiederholbarer Weg (YAML, `state: present`, `identifiers`), werden vom
   Worker asynchron angewendet und melden keinen Unterschied je Objekt; die API dafür ist
   beobachtet (8.1). `ensure_*` ist der programmatische Weg aus Perl mit sofortiger Antwort
   und `changed`. Beide schreiben in dieselben Tabellen; ein Objekt trägt kein Merkmal, das
   sagt, wem es gehört (nur Default-Mappings haben `managed`). **Vorschlag:** `ensure_*` für
   alles, was aus Perl heraus entschieden wird (Tests, Airlock-Setup); Blueprints für
   Flows mit vielen Stages und Bindings, wenn jemand sie als Datei pflegen will, über
   `create_blueprint`/`apply_blueprint` plus Warten in Phase 2. Die Dist schützt
   Blueprint-Objekte nicht vor `ensure_*`; wer beides auf dasselbe Objekt richtet, bekommt,
   was er bestellt hat, und die POD sagt das.
5. **`grant_types` beim Anlegen eines Providers.** Ohne Angabe ist der Provider nutzlos
   (`invalid_grant` auf alles). Drei Wege: (a) Validation-Fehler, (b) ein Default wie
   `[authorization_code, refresh_token]`, (c) alle acht. **Vorschlag: (a)**, damit nie ein
   Provider mit geratenem Verhalten entsteht; `create_oauth2_provider` bleibt roh und
   schickt, was es bekommt.
6. **Namensauflösung in `ensure_*` oder rohe Kennungen?** authentik verlangt UUIDs und PKs,
   wo ein Mensch Slug, Name oder Scope kennt. Ohne Auflösung muss jeder Aufrufer erst fünf
   `find_*` machen; mit Auflösung hat `ensure_oauth2_provider` einen eigenen Vokabelsatz
   (`scopes` statt `property_mappings`). **Vorschlag:** Auflösung nur für die in 5.2
   genannten Felder, erkannt daran, dass der Wert kein UUID/Integer ist; rohe Kennungen gehen
   weiter durch. `scopes` ist ein zusätzlicher Schlüssel, `property_mappings` bleibt erlaubt;
   beide zugleich sind ein Validation-Fehler.
7. **Flow-Executor als öffentliche Klasse?** Airlocks Live-Tests und diese Live-Suite
   brauchen den Login per HTTP (8.3). Für Phase 1 liegt er als Hilfsmodul in `t/lib`, damit
   die öffentliche API klein bleibt. **Vorschlag:** in Phase 2 als `WWW::Authentik::Flow`
   (`start($slug)`, `submit(\%answer)`, `cookies`), sobald Airlock ihn aus seinem eigenen
   `t/` heraus braucht und die Form zweimal gesehen wurde.
8. **Wie wird die Testinstanz bereitgestellt?** `t/authentik/docker-compose.yml` ist das
   Compose-File der Wegwerf-Instanz (Ports an `127.0.0.1`, kein Docker-Socket, kein Root im
   Worker, Image festgenagelt), `t/authentik/env.example` die Variablen. Ein Entwickler kopiert
   `env.example` nach `.env`, füllt die vier Geheimnisse, `docker compose up -d`, wartet auf
   `/-/health/ready/` (hier 115 s) und setzt `AUTHENTIK_URL=http://127.0.0.1:9000
   AUTHENTIK_TOKEN=<Bootstrap-Token>`. Für CI: ein eigener Job `live` in
   `.github/workflows/ci.yml`, der dasselbe Compose-File mit erzeugten Geheimnissen startet,
   auf Readiness wartet und die Live-Suite fährt; wegen Image-Größe (≈1 GB) und Startzeit nur
   auf `main` und per `workflow_dispatch`, nicht je Pull-Request. **Vorschlag: so;** der
   Standardlauf `prove -lr t` bleibt ohne Instanz grün.
9. **Was tun mit dem kaputten `POST /authenticators/admin/totp/`?** Die Live-Suite richtet
   TOTP über den Setup-Flow ein (8.3), was ohnehin der Weg eines echten Nutzers ist.
   **Vorschlag:** keinen Workaround in der Dist, den Fehler upstream melden (ohne eigene
   Initiative hier; das ist Gettys Entscheidung).

## 12. Aus dem Review bei der Freigabe (2026-10-04)

Für den Plan; wo diese Punkte dem Text oben widersprechen oder ihn schärfen, gelten sie.

- **Rückgabeform weicht bewusst von Keycloak ab.** `ensure_*` liefert `{ object, changed }`
  statt `{ id, changed }`, und `create_*`/`update_*` liefern die Repräsentation statt der ID.
  Der Grund steht in 5.2; die POD der Fassade nennt den Unterschied für Umsteiger.
- **Die Namensauflösung darf nicht raten.** „Kein UUID/Integer“ als Erkennung (Punkt 6)
  verwechselt einen Provider namens `123` mit einem PK. Der Plan legt je Feld fest, welche
  Form als rohe Kennung gilt, und testet den Fall eines Namens, der wie eine Kennung aussieht.
- **`verify_token( type => ... )` ist eine Heuristik** (Claim `scope`, Abschnitt 6.1) und wird
  in der POD so benannt; ohne `type` wird die Tokenart nicht geprüft.
- **Erzwungenes TOTP ist vor dem Bau zu beobachten.** `not_configured_action: deny` an der
  Validation-Stage (6.2, 8.4) ist der Fall, den Airlock braucht: Login ohne eingerichtetes
  TOTP, Antwort des Executors, und `amr` nach dem Login mit TOTP.

## 13. Nach dem Bau geklärt (2026-10-04)

Beim Bau von Phase 1 und bei einem unabhängigen Review mit Proben gegen das laufende
authentik 2026.8.3 sind Punkte aufgetaucht, die die Beobachtung in Abschnitt 8 nicht
abgedeckt hatte. Sie sind behoben und durch Tests festgehalten; wo sie dem Text oben
widersprechen, gelten sie.

### 13.1 Beim Bauen gefunden

- **Ein User-Agent darf `TE` nicht ankündigen.** LWP schickt standardmäßig
  `TE: deflate,gzip;q=0.3` und `Connection: TE, close`. authentik beantwortet **jede zweite**
  Anfrage, die den Verbindungs-Token `TE` trägt, überhaupt nicht: der Aufruf steht bis zum
  Timeout, der nächste geht, der übernächste steht wieder. Mit rohen Sockets nachgestellt,
  also authentiks Frontend und nicht LWP:

  | Anfrage | Antwort |
  |---|---|
  | `Connection: close` viermal hintereinander | viermal 200 |
  | `Connection: TE, close` viermal hintereinander | 200, nichts, 200, nichts |
  | `Connection: TE` viermal hintereinander | viermal nichts |

  `WWW::Authentik->default_ua` setzt deshalb `send_te => 0`, was `Net::HTTP` die Header
  weglassen lässt. Ein eingeschleuster `ua` ohne diese Einstellung hängt; die POD der
  Fassade sagt das. Ohne diesen Fund wäre die Dist gegen ein echtes authentik unbenutzbar
  gewesen, und kein Unit-Test gegen das nachgebaute authentik hätte es gezeigt.
- **authentik nimmt denselben TOTP-Code nicht zweimal.** Ein Login unmittelbar nach der
  Einrichtung oder ein zweiter Login im selben 30-Sekunden-Fenster wird mit
  `{"code":[{"code":"invalid","string":"Invalid Token. Please ensure the time on your device
  is accurate and try again."}]}` abgelehnt. Das Executor-Hilfsmodul wartet deshalb auf das
  nächste Fenster und schickt den Code noch einmal.
- **Der Service-Account des Client-Credentials-Grants überlebt seinen Provider.** authentik
  legt beim ersten `client_credentials` einen Nutzer `ak-<provider>-client_credentials`
  (`path: goauthentik.io/apps/<slug>`) an; das Löschen von Provider und Application nimmt ihn
  nicht mit. Fünf Läufe der Live-Suite hinterließen fünf Nutzer. Die Suite räumt ihn jetzt
  selbst weg, und `delete_oauth2_provider` ist damit kein vollständiges Aufräumen.
- **Ein Stage-Name gehört genau einem Stage-Typ.** Namen sind über alle Typen eindeutig, und
  das typisierte Detail-Endpunkt eines fremden Typs antwortet 404
  (`GET /stages/user_login/<UUID einer Password-Stage>/` →
  `{"detail":"No UserLoginStage matches the given query."}`). `ensure_stage` ließ diese 404
  durch und meldete etwas Unverständliches; es wirft jetzt einen Validation-Fehler, der sagt,
  welchem Typ der Name wirklich gehört. Das nachgebaute authentik lieferte die Stage auch
  über den falschen Typ aus und verbarg den Fall — es filtert jetzt nach Typ.

### 13.2 Vom unabhängigen Review gefunden

Ein Review ohne Bau-Kontext, mit Proben gegen dieselbe laufende Instanz.

- **authentik schneidet jedes Textfeld zu, und `ensure_*` konvergierte dadurch nicht.**
  Jedes `CharField` und `TextField` wird beim Speichern an beiden Enden von Leerraum
  befreit (DRF mit `trim_whitespace`), beobachtet an `name`, `email`, `slug`,
  `meta_description` und `expression`:

  | geschickt | gespeichert |
  |---|---|
  | `{"name":"  padded both  "}` | `"padded both"` |
  | `{"expression":"return {}\n"}` | `"return {}"` |
  | `{"meta_description":"two lines\n"}` | `"two lines"` |
  | `{"attributes":{"padded":"  keep me  "}}` | `{"padded":"  keep me  "}` — **nicht** zugeschnitten |

  Ein gewünschter Wert mit Leerraum am Rand war damit nie erreichbar: `ensure_*` meldete
  bei jedem Lauf `updated` und schrieb jedes Mal. Dreimal hintereinander beobachtet an
  `ensure_scope_mapping` mit einem Ausdruck, der auf `\n` endet. `WWW::Authentik::Diff`
  nimmt jetzt einen gespeicherten Wert als gleich an, wenn er genau die zugeschnittene
  Form des gewünschten ist — nur in dieser Richtung, damit Leerraum in `attributes`, den
  authentik behält, weiter als Unterschied zählt.

- **`verify_token` nahm das Token einer anderen Application an.** Alle Provider einer
  authentik-Instanz signieren mit demselben Schlüssel, der Aussteller ist also das
  Einzige, was zwei Applications trennt — und mit `issuer_mode: global` ist er für alle
  die nackte Instanz-Adresse. Zwei Provider, beide auf `global`, am laufenden System:
  das Access-Token und das ID-Token des einen wurden vom `oidc` des anderen ohne
  `audience` angenommen. Behoben: `WWW::Authentik::OIDC` hat ein optionales `client_id`,
  das als `audience` geprüft wird, `issuer_names_the_application` sagt, ob der Aussteller
  die Application benennt, und `verify_token` verweigert die Prüfung, wenn er es nicht
  tut und weder `audience` noch `client_id` noch `any_audience => 1` da ist. Mit dem
  Standard `issuer_mode: per_provider` ändert sich nichts.
- **Eine komprimierte Antwort ging ganz verloren.** `read_response` maß `decoded_content`,
  dekodierte aber `content`. Mit einem eingeschleusten User-Agent, der `gzip` anfragt,
  kam bei Status 200 `data => undef` zurück, ohne Fehler: `get_user` lieferte nichts,
  `list_*` eine leere Liste, und `ensure_*` hätte Doppelgänger angelegt. Jetzt wird
  `decoded_content( charset => 'none' )` dekodiert.
- **Ein Rumpf, der nicht von authentik kommt, war stumm.** Ein Proxy oder eine falsche
  `base_url` antwortet HTML oder Text; der Fehler trug dann nur die Statuszeile. Jetzt
  steht ein zusammengestrichener Ausschnitt in `api_message` und der Rumpf (bis 500
  Zeichen) in `WWW::Authentik::Error::API->body`.
- **`scopes => undef` hätte jede Zuordnung entfernt.** Es wurde als leere Liste gelesen und
  hätte einem vorhandenen Provider alle Property-Mappings genommen. Jetzt ein
  Validation-Fehler, ebenso `<feld>_name => undef`, das vorher stillschweigend verfiel,
  und eine Referenz, wo ein Name hingehört.
- **Ein `find_*` ohne Schlüssel holte die ganze Tabelle** und verglich jede Zeile mit
  `undef`, mit einer Warnung je Zeile. Jetzt ein Validation-Fehler.
- **`Diff::_bool` endete in einem nackten `return`,** das im Listenkontext nichts liefert
  und den zweiten Wert in den ersten Platz geschoben hätte. Jetzt `return undef`.
- **`LWP::UserAgent` ist auf 6.33 festgenagelt,** die erste Version mit `send_te`. Eine
  ältere nimmt die Option stumm nicht an (sie warnt nur unter `-w`), und der Hang aus
  13.1 wäre zurück. `default_ua` prüft es zusätzlich zur Laufzeit.
- **Nicht bestätigt: `check_access` ignoriere einen unbekannten `for_user`.** Der Review
  schloss das aus `?for_user=1` → `passing: true`, obwohl `/core/users/1/` 404 gibt. Die
  Nachprüfung zeigt etwas anderes: ein wirklich unbekannter Schlüssel ist
  `400 {"for_user": "User not found"}`, und der Schlüssel 1 gehört authentiks internem
  `AnonymousUser`, den die Nutzer-Endpunkte nur nicht zeigen. Beides steht jetzt in der
  POD und in der Live-Suite.

