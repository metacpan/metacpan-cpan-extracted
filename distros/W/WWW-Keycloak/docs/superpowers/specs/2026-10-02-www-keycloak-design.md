# WWW::Keycloak – Design

Datum: 2026-10-02
Status: freigegeben am 2026-10-03; die Entscheidungen aus Abschnitt 11 sind getroffen.
Distribution: `WWW-Keycloak` (Repo `p5-www-keycloak`), CPAN-fähig, `[@Author::GETTY]`
Zwilling: `Net-Async-Keycloak` (Repo `p5-net-async-keycloak`), folgt diesem Design mit `_f`-Methoden.

## 1. Was WWW::Keycloak ist

**WWW::Keycloak ist der Perl-Client für Keycloak: OIDC gegen einen Realm und die
Admin-REST-API, mit der man einen Realm aus Perl heraus in einen gewünschten Zustand
bringt.**

Der zweite Teil ist der eigentliche Grund für die Dist. Ein Keycloak, das man von Hand in
der Admin-Konsole zusammenklickt, ist nicht wiederholbar. Der Anlass war konkret: Damit
Keycloak im Token meldet, ob ein zweiter Faktor benutzt wurde, braucht ein Realm einen
Protocol-Mapper und Referenzwerte an vier Schritten zweier Authentication-Flows. Das
steht heute als 80-Zeilen-Skript mit rohem `HTTP::Tiny` in `p5-airlock/t/keycloak/setup.pl`.
Mit dieser Dist soll es so aussehen:

```perl
my $kc = WWW::Keycloak->new(
  base_url => 'http://pichu.cihq:30523',
  realm    => 'airlock-test',
  username => 'admin',
  password => 'admin',
);

$kc->admin->ensure_execution_config(
  flow          => 'browser',
  authenticator => 'auth-otp-form',
  config        => { 'default.reference.value' => 'otp', 'default.reference.maxAge' => 3600 },
);
```

### Was WWW::Keycloak nicht ist

- **Kein Deployment-Werkzeug.** Keycloak starten, Datenbank, Ingress, Zertifikate gehören
  dem Cluster (OCP). Diese Dist redet mit einem Keycloak, das schon läuft.
- **Kein Ersatz für den Realm-Import.** Was sich importieren lässt und nie wieder ändert,
  darf weiter als JSON importiert werden. Die Dist ist für das, was danach kommt und was
  sich wiederholen lassen muss.
- **Kein Browser.** Login-Seiten durchklicken ist kein Teil der API (der Airlock-Live-Test
  macht das für sich selbst).
- **Keine vollständige Abdeckung der Admin-API in Phase 1.** Rollen, Gruppen, Identity
  Provider, Events und User Federation kommen, wenn sie gebraucht werden.

## 2. Aufbau

```
WWW::Keycloak                   Fassade: base_url, realm, Zugangsdaten, ua
  ├─ ->oidc    WWW::Keycloak::OIDC     Discovery, JWKS, Token prüfen, Token holen
  ├─ ->admin   WWW::Keycloak::Admin    Admin-REST-API des Realms
  └─ ->for_realm('x')                  dieselbe Fassade für einen anderen Realm

WWW::Keycloak::Auth             Admin-Token holen, erneuern, bei 401 einmal neu
WWW::Keycloak::Error            ::Validation, ::Network, ::API (ein Paket pro Datei)
```

Form und Namen folgen `WWW::Zitadel`: Moo, eine Klasse pro Belang, eine gemeinsame
`LWP::UserAgent`-Instanz (über `ua` injizierbar), direkte Methoden statt verschachtelter
Sub-Clients (`$admin->list_users`, nicht `$admin->users->list`).

Zwei Dinge sind bei Keycloak anders als bei Zitadel und prägen den Aufbau:

1. **Der Realm ist Teil der Adresse.** OIDC liegt unter `<base_url>/realms/<realm>`, die
   Admin-API unter `<base_url>/admin/realms/<realm>`. Der Realm ist deshalb ein
   Pflichtattribut der Fassade, kein Parameter jeder Methode. `->for_realm('anderer')` liefert
   eine zweite Fassade mit derselben `ua` und derselben Anmeldung.
2. **Admin-Tokens sind kurzlebig.** Es gibt kein Personal Access Token. Das Admin-Token
   kommt aus einem OIDC-Login und läuft nach kurzer Zeit ab (ein neuer Realm hat
   `accessTokenLifespan` 300 Sekunden). Die Dist muss es selbst
   erneuern (Abschnitt 4).

## 3. Fassade

```perl
my $kc = WWW::Keycloak->new(
  base_url => 'https://id.example.org',   # Pflicht, ohne /realms/...
  realm    => 'main',                     # Pflicht

  # Anmeldung an der Admin-API, eine der drei Formen:
  username => 'admin', password => '...',                    # Passwort-Grant über admin-cli
  client_id => 'provisioner', client_secret => '...',        # Service-Account
  token => $bearer,                                          # fertiges Token, wird nicht erneuert

  auth_realm => 'master',   # wo sich der Admin anmeldet; Standard: 'master' bei
                            # username/password, sonst der eigene Realm
  ua         => $lwp,       # optional
);

$kc->issuer;        # https://id.example.org/realms/main
$kc->oidc;          # WWW::Keycloak::OIDC
$kc->admin;         # WWW::Keycloak::Admin
$kc->realm;             # 'main'
$kc->for_realm('dev');  # Fassade für einen anderen Realm, gleiche Anmeldung
```

`base_url` und `realm` leer oder fehlend: `WWW::Keycloak::Error::Validation`. Ohne
Zugangsdaten funktioniert `oidc`; `admin` wirft beim ersten Aufruf eine Validation-Exception.

## 4. Anmeldung an der Admin-API (`WWW::Keycloak::Auth`)

Eine kleine Klasse mit einer Aufgabe: ein gültiges Bearer-Token liefern.

- Holt das Token beim ersten Bedarf am Token-Endpunkt von `auth_realm`.
- Merkt sich `expires_in` und erneuert 30 Sekunden vor Ablauf; mit `refresh_token`, wenn
  es eines gibt und es noch gilt, sonst durch erneute Anmeldung.
- `Admin` wiederholt eine Anfrage genau einmal mit frischem Token, wenn sie mit 401
  beantwortet wird (beobachtet: ein Keycloak-Neustart macht alle Tokens ungültig).
- Die Zeit ist injizierbar (`now`), damit Tests Ablauf ohne `sleep` prüfen.
- Passwort und Client-Secret erscheinen in keiner Exception und in keinem Log.

## 5. Admin-API (`WWW::Keycloak::Admin`)

### 5.1 Grundoperationen

Jede Methode ist ein dünner Aufruf eines Endpunkts. Rückgaben: `get_*` und `find_*`
liefern die Repräsentation als Hash (oder nichts bei `find_*` ohne Treffer), `list_*`
eine Array-Referenz, `create_*` die ID des neuen Objekts, `update_*` und `delete_*` wahr.

Keycloak beantwortet ein `POST` zum Anlegen mit `201`, leerem Body und der Adresse des
neuen Objekts im `Location`-Header. `create_*` liest die ID von dort.

| Bereich | Methoden |
|---|---|
| Server | `server_info` |
| Realm | `get_realm`, `create_realm(\%rep)`, `update_realm(\%changes)`, `delete_realm`, `export_realm(%opt)`, `partial_import(\%rep, if_exists => 'SKIP')` |
| Clients | `list_clients(%query)`, `find_client($client_id)`, `get_client($id)`, `create_client(\%rep)`, `update_client($id, \%rep)`, `delete_client($id)`, `get_client_secret($id)`, `regenerate_client_secret($id)`, `get_service_account_user($id)` |
| Client-Scopes | `list_client_scopes`, `find_client_scope($name)`, `create_client_scope(\%rep)`, `update_client_scope($id, \%rep)`, `delete_client_scope($id)`, `add_default_client_scope($client_id_uuid, $scope_id)`, `add_realm_default_client_scope($scope_id)` |
| Protocol-Mapper | `list_protocol_mappers(client => $id \| client_scope => $id)`, `create_protocol_mapper(client => $id, \%rep)`, `update_protocol_mapper(...)`, `delete_protocol_mapper(...)` |
| Nutzer | `list_users(%query)`, `find_user($username)`, `get_user($id)`, `create_user(\%rep)`, `update_user($id, \%rep)`, `delete_user($id)`, `set_password($id, $password, temporary => 0)`, `list_credentials($id)`, `delete_credential($id, $credential_id)`, `list_sessions($id)`, `logout_user($id)` |
| Authentication | `list_flows`, `list_executions($flow_alias)`, `copy_flow($alias, $new_name)`, `get_execution_config($config_id)`, `create_execution_config($execution_id, \%rep)`, `update_execution_config($config_id, \%rep)`, `describe_authenticator($provider_id)` |

`find_client` sucht über `clientId` (die sprechende Kennung), `get_client` nimmt die
interne UUID. Diese Doppelung ist Keycloaks Datenmodell und wird nicht versteckt, aber die
`ensure_*`-Methoden nehmen überall die sprechende Kennung.

### 5.2 `ensure_*`: gewünschter Zustand statt Einzelschritt

Die Grundoperationen sind nicht wiederholbar: Ein zweites `create_client` gibt 409. Für
ein Setup, das man beliebig oft laufen lassen kann, gibt es zu jedem Objekt eine
`ensure_*`-Methode. Sie sucht das Objekt, legt es an oder gleicht es ab, und sagt, was sie
getan hat.

```perl
my $r = $admin->ensure_client(
  clientId     => 'my-cli',
  publicClient => \1,
  attributes   => { 'oauth2.device.authorization.grant.enabled' => 'true' },
);
$r->{id};        # interne UUID
$r->{changed};   # 'created', 'updated' oder '' (nichts zu tun)
```

| Methode | Schlüssel, über den gesucht wird |
|---|---|
| `ensure_realm(%rep)` | der Realm der Fassade |
| `ensure_client(%rep)` | `clientId` |
| `ensure_client_scope(%rep)` | `name` |
| `ensure_protocol_mapper(client => $client_id \| client_scope => $name, %rep)` | `name` innerhalb des Clients oder Scopes |
| `ensure_user(%rep)` | `username` |
| `ensure_execution_config(flow => $alias, authenticator => $provider_id, config => \%c)` | der Schritt mit diesem Authenticator im Flow |

Regeln, die für alle gelten:

- **Abgeglichen wird nur, was angegeben ist.** Schlüssel, die der Aufrufer nicht nennt,
  bleiben, wie sie sind. `attributes` und `config` werden schlüsselweise zusammengeführt,
  nicht ersetzt.
- **Erst vergleichen, dann schreiben.** Stimmt der Zustand schon, gibt es keinen
  schreibenden Aufruf und `changed` ist leer. Ein Setup-Lauf, der nichts ändert, ist damit
  als solcher erkennbar.
- **`ensure_user` fasst Zugangsdaten nur beim Anlegen an.** Ein Passwort wird nicht bei
  jedem Lauf zurückgesetzt. Wer das will, ruft `set_password`.
- **Nichts wird gelöscht.** `ensure_*` entfernt keine Objekte und keine Schlüssel.

### 5.3 Was sich nicht über die Nutzer-API anlegen lässt

Keycloak maskiert in Exporten die Werte der Authenticator-Konfiguration
(`"default.reference.value": "**********"`), und ein Realm-Import mit eigenen Flows muss
alle 21 eingebauten Flows ausbuchstabieren. Deshalb ist `ensure_execution_config` der Weg
für Flow-Einstellungen, nicht der Import.

Ein OTP-Credential mit bekanntem Geheimnis lässt sich dagegen über `update_user` und über
`partial_import` setzen (beides beobachtet). `ensure_user` nimmt `credentials` beim
Anlegen entgegen und reicht sie durch.

## 6. OIDC (`WWW::Keycloak::OIDC`)

Wie `WWW::Zitadel::OIDC`, ergänzt um das, was Keycloak-typisch gebraucht wird:

| Methode | Zweck |
|---|---|
| `discovery`, `jwks`, `*_endpoint` | Metadaten, mit Cache; `jwks(force_refresh => 1)` |
| `verify_token($jwt, audience => ...)` | Signatur, `iss`, `exp`, optional `aud`; bei unbekanntem Schlüssel einmal JWKS neu laden |
| `userinfo($access_token)`, `introspect($token, client_id =>, client_secret =>)` | |
| `password_token(client_id =>, username =>, password =>, totp =>, scope =>)` | Direct Grant; `totp` für Nutzer mit OTP |
| `client_credentials_token(client_id =>, client_secret =>, scope =>)` | |
| `refresh_token($refresh_token, client_id => ...)` | |
| `exchange_authorization_code(code =>, redirect_uri =>, client_id => ...)` | |
| `device_authorization(client_id =>, scope =>)`, `device_token(device_code =>, client_id =>)` | ein Schritt des Device-Flows; die Poll-Schleife ist Sache des Aufrufers oder von `Airlock::Client` |
| `logout(refresh_token =>, client_id => ...)` | Sitzung beenden |

`verify_token` akzeptiert standardmäßig nur `RS*`, `PS*` und `ES*` und nie `none` oder HMAC.
Mit `type => 'Bearer'` prüft es zusätzlich `typ`, damit ein ID-Token nicht als Access-Token
durchgeht. Bei unbekanntem Schlüssel lädt es die JWKS neu, aber nur aus diesem Grund und
höchstens einmal pro `jwks_min_age` (60 Sekunden).

## 7. Fehler

Wie bei `WWW::Zitadel`, ein Paket pro Datei:

- `WWW::Keycloak::Error` — Basis mit `message`, stringifiziert zu ihr.
- `WWW::Keycloak::Error::Validation` — falsche Argumente, fehlende Zugangsdaten.
- `WWW::Keycloak::Error::Network` — keine Antwort.
- `WWW::Keycloak::Error::API` — HTTP 4xx/5xx, mit `http_status` (Zahl), `api_message` und
  den Prädikaten `is_not_found` (404), `is_conflict` (409), `is_unauthorized` (401).

Keycloak meldet Fehler der Admin-API in zwei Formen, beide werden zu `api_message`:
`{"errorMessage":"Client probe-cli already exists"}` und `{"error":"Could not find client"}`.
Der Token-Endpunkt nutzt die OAuth-Form `{"error":"invalid_grant","error_description":"..."}`.

## 8. Am laufenden Keycloak beobachtet

Keycloak 26.8.0, 2026-10-02, Wegwerf-Realm. Jede Zeile ist ein tatsächlich abgesetzter
Aufruf. Pfade relativ zu `<base_url>/admin`, `{r}` ist der Realm.

| Aufruf | Antwort |
|---|---|
| `POST /realms` | 201, `Location`; zweites Mal 409 `errorMessage` |
| `GET /realms/{r}`, `PUT /realms/{r}`, `DELETE /realms/{r}` | 200 / 204 / 204; danach `GET` 404 `{"error":"Realm not found."}` |
| `POST /realms/{r}/partial-export?exportClients=true` | 200; Authenticator-Config-Werte maskiert |
| `POST /realms/{r}/partialImport` | 200 `{added, skipped, overwritten}`; legt Nutzer mit Passwort und OTP an |
| `POST /realms/{r}/clients` | 201, `Location` endet auf die UUID; zweites Mal 409 |
| `GET /realms/{r}/clients?clientId=x` | 200, Liste mit einem Eintrag |
| `GET`/`PUT`/`DELETE /realms/{r}/clients/{id}` | 200 / 204 / 204; danach 404 `{"error":"Could not find client"}` |
| `GET`/`POST /realms/{r}/clients/{id}/client-secret` | 200 |
| `GET /realms/{r}/clients/{id}/service-account-user` | 200, `service-account-<clientId>` |
| `GET`/`POST /realms/{r}/clients/{id}/protocol-mappers/models` | 200 / 201; gleicher Name 409 |
| `GET`/`POST /realms/{r}/client-scopes`, `POST .../client-scopes/{id}/protocol-mappers/models` | 200 / 201 / 201 |
| `PUT /realms/{r}/default-default-client-scopes/{id}`, `PUT /realms/{r}/clients/{id}/default-client-scopes/{scopeId}` | 204 / 204 |
| `POST /realms/{r}/users` (mit `credentials`) | 201, `Location`; zweites Mal 409 |
| `GET /realms/{r}/users?username=x&exact=true` | 200, Liste |
| `PUT /realms/{r}/users/{id}` | 204; setzt auch ein OTP-Credential (`secretData`, `credentialData`) |
| `PUT /realms/{r}/users/{id}/reset-password` | 204 |
| `GET /realms/{r}/users/{id}/credentials`, `GET .../sessions`, `POST .../logout`, `DELETE /realms/{r}/users/{id}` | 200 / 200 / 204 / 204 |
| `GET /realms/{r}/authentication/flows` | 200; 7 eingebaute Flows auf oberster Ebene |
| `GET /realms/{r}/authentication/flows/{alias}/executions` | 200; flache Liste mit `level`, `providerId`, `authenticationConfig` |
| `POST /realms/{r}/authentication/executions/{id}/config` | 201, auch an eingebauten Flows |
| `PUT /realms/{r}/authentication/config/{configId}` | 204 |
| `POST /realms/{r}/authentication/flows/{alias}/copy` | 201 |
| `GET /realms/{r}/authentication/config-description/{providerId}` | 200; für `auth-otp-form` ohne Eigenschaften, die Referenzwerte stehen dort nicht |
| `GET /serverinfo` | 200; Version, `protocolMapperTypes` (darunter `oidc-amr-mapper`) |
| beliebiger Aufruf mit ungültigem Token | 401 `{"error":"HTTP 401 Unauthorized"}` |

Dazu aus dem Airlock-Live-Test, für `oidc`:

- Admin-Login: `POST /realms/master/protocol/openid-connect/token` mit `grant_type=password`,
  `client_id=admin-cli`.
- Der Direct Grant nimmt den Parameter `totp`; ein Nutzer mit OTP bekommt ohne ihn
  `invalid_grant`.
- Discovery nennt `device_authorization_endpoint`; die Device-Antwort enthält
  `verification_uri_complete`.
- `amr` erscheint im Token erst mit dem Mapper `oidc-amr-mapper` und den Schlüsseln
  `default.reference.value` / `default.reference.maxAge` an den Flow-Schritten. `acr`
  bleibt `1`.
- Der Bootstrap-Admin kommt über `KC_BOOTSTRAP_ADMIN_USERNAME` / `KC_BOOTSTRAP_ADMIN_PASSWORD`.

Nicht beobachtet und deshalb im Plan vor dem Bauen zu prüfen: `GET /realms/{r}/authentication/config/{configId}`,
die Aktualisierung von Protocol-Mappern und Client-Scopes per `PUT`, Service-Account-Anmeldung
an der Admin-API (welche `realm-management`-Rollen nötig sind), `introspect`, `logout`
über den End-Session- oder Revocation-Endpunkt, und das Verhalten älterer
Keycloak-Versionen (vor 17 lag alles unter `/auth`).

## 9. Zwilling

`Net::Async::Keycloak` spiegelt die öffentliche API mit `_f`-Suffix und Futures, nach dem
Muster von `Net::Async::Zitadel`: gleiche Klassen, gleiche Methoden, gleiche
Fehlerhierarchie. Diese Dist führt; der Zwilling folgt je Phase.

Die Logik der `ensure_*`-Methoden (suchen, vergleichen, anlegen oder abgleichen) existiert
dadurch zweimal. Damit sie nicht auseinanderläuft, liegt der Vergleich in einer reinen
Funktion ohne I/O: `WWW::Keycloak::Diff->changes(\%current, \%wanted)` liefert die zu
schreibenden Schlüssel. Beide Dists benutzen dieselbe Funktion; `Net-Async-Keycloak` hängt
dafür von `WWW-Keycloak` ab. Alles mit I/O wird im Zwilling eigenständig geschrieben.

## 10. Tests und Phasen

- **Unit-Tests** mit gemocktem HTTP nach dem Muster von `p5-www-zitadel/t/02-oidc.t` und
  `t/03-management.t`: jede Methode gegen die in Abschnitt 8 beobachteten Antworten.
- **`WWW::Keycloak::Diff`** rein, ohne HTTP: verschachtelte Hashes, `attributes`/`config`
  zusammenführen, Booleans (`\1`, `JSON->true`, `"true"`), nichts zu tun.
- **`WWW::Keycloak::Auth`** mit gestellter Uhr: Erneuern vor Ablauf, Refresh-Token,
  Wiederholung nach 401 genau einmal.
- **Live-Suite** (`t/90-live-keycloak.t`, nur mit `KEYCLOAK_LIVE_TEST=1 KEYCLOAK_URL=...`):
  legt einen Realm mit zufälligem Namen an, fährt jede `ensure_*`-Methode zweimal (erst
  `created`, dann leer), prüft OIDC gegen diesen Realm und löscht ihn wieder. Das Manifest
  für ein Wegwerf-Keycloak auf Kubernetes liegt in `p5-airlock/t/keycloak/k8s.yaml` und
  wird übernommen.

| Phase | Inhalt |
|---|---|
| 1 | Fassade, Fehler, `Auth`, `Admin`-Grundoperationen aus 5.1, `ensure_*` aus 5.2, `Diff`, `OIDC`, Unit-Tests, Live-Suite. Erster Nutzer: `p5-airlock/t/keycloak/setup.pl` wird auf diese Dist umgestellt. |
| 2 | Deklaratives Setup (Abschnitt 11, Punkt 1), Rollen und Rollen-Zuweisung, Gruppen |
| 3 | Identity Provider, Events, User Federation, Step-up-Flows mit ACR-zu-LoA-Abbildung |

Der Zwilling zieht nach jeder Phase nach.

Abhängigkeiten: `Moo`, `LWP::UserAgent`, `HTTP::Request`, `JSON::MaybeXS`, `Crypt::JWT`,
`URI`, `Types::Standard`, `namespace::autoclean`. HTTPS über `LWP::Protocol::https`.

## 11. Entscheidungen (getroffen 2026-10-03, jeweils wie vorgeschlagen)

1. **Wie sieht das „automatische Setup“ aus?** Zwei Wege, die sich nicht ausschließen:
   - *Im Code:* Ein Perl-Skript ruft `ensure_*` der Reihe nach. Das ist mit Phase 1 fertig.
   - *Deklarativ:* Eine Datei (YAML oder ein Perl-Hash) beschreibt Realm, Clients, Scopes,
     Nutzer und Flow-Einstellungen; `WWW::Keycloak::Setup->new( keycloak => $kc )->apply($spec)`
     läuft die `ensure_*` in der richtigen Reihenfolge ab und meldet, was sich geändert
     hat. Dazu ein `bin/keycloak-setup`. Vorschlag: Phase 2, sobald das erste echte Setup
     (Mothership oder das Lab) zeigt, welche Felder die Datei wirklich braucht.
2. **Womit meldet sich das Setup an?** Für Tests reicht der Bootstrap-Admin. Für einen
   dauerhaften Betrieb ist ein Service-Account-Client mit `realm-management`-Rollen der
   übliche Weg; den müsste das erste Setup selbst anlegen. Vorschlag: Phase 1 kann beide
   Anmeldeformen, das Anlegen des Service-Accounts samt Rollen kommt mit den Rollen in
   Phase 2.
3. **Wo läuft das Keycloak, gegen das entwickelt wird?** Heute: Namespace `airlock-test`
   auf `cihq`, ohne Persistenz, per NodePort, auf pichu festgenagelt, weil raichus
   VM-CPU-Modell kein x86-64-v2 kann. Für mehr als Tests braucht der Cluster eine
   StorageClass und ein programmiertes Gateway.
4. **Gemeinsame `Diff`-Funktion oder volle Doppelung im Zwilling?** Abschnitt 9 schlägt
   die gemeinsame Funktion vor; der Preis ist eine Abhängigkeit von `Net-Async-Keycloak`
   auf `WWW-Keycloak`, die es zwischen den Zitadel-Zwillingen nicht gibt.

## 12. Nach dem Bau geklärt (2026-10-03)

Ein unabhängiger Review mit Proben gegen das echte Keycloak 26.8.0 hat Punkte gefunden, die
Unit- und Live-Tests nicht abgedeckt hatten. Sie sind behoben und durch Tests gegen das
nachgebaute wie das echte Keycloak festgehalten; wo sie dem Text oben widersprechen, gelten sie.

- **`ensure_user` schickt den ganzen Nutzer.** Ein `PUT` mit `attributes` lässt Keycloaks
  User-Profile die nicht genannten Felder (`email`, `firstName`, `lastName`) löschen.
  Attributwerte werden als Listen verglichen; ein einzelner Wert darf als String kommen.
  Attribute, die das User-Profile nicht kennt, verwirft Keycloak, solange es nicht
  unverwaltete Attribute erlaubt; sie melden dann bei jedem Lauf `updated`.
- **Listen aus einfachen Werten sind Mengen.** Keycloak gibt `redirectUris` und `webOrigins`
  sortiert zurück; ein Vergleich in Reihenfolge hätte nie konvergiert.
- **`ensure_client` verweigert `defaultClientScopes`, `optionalClientScopes` und
  `protocolMappers`.** Keycloak übernimmt sie beim Anlegen, ignoriert sie aber beim
  Aktualisieren. Dafür gibt es `add_default_client_scope` und `ensure_protocol_mapper`.
- **`ensure_execution_config` ersetzt statt zusammenzuführen** und meldet bei jedem Lauf
  `updated`: Keycloak liefert diese Werte beim Lesen als `**********`. Abschnitt 5.2
  („erst vergleichen, dann schreiben“) gilt für diese eine Methode nicht.
- **Ein fehlgeschlagener Admin-Login wird nicht als abgelehntes Token wiederholt**; das
  Secret geht genau einmal an Keycloak. Ein falsches Passwort beantwortet Keycloak mit 400
  `invalid_grant`, nicht mit 401.
- **Die Standard-`ua` folgt keinen Redirects,** damit das Admin-Token nirgendwohin
  weitergereicht wird. Der Realm wird in allen Adressen URI-kodiert.
