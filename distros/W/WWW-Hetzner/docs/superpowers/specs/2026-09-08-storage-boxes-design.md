# Design: Storage Boxes (api.hetzner.com)

- Ticket: karr #5 (Board `WWW-Hetzner`)
- Datum: 2026-09-08
- Status: Freigegeben am 2026-09-08, vollständiger Umfang
- Voraussetzungen: Action-Namespace #10; HTTP-Korrekturen #11/#13; additive Pagination #12

## Problem und Ziel

`WWW::Hetzner` verspricht Cloud, Storage und Robot, bietet bisher aber keinen
Client für `api.hetzner.com`. Ein eigener Storage-Client ergänzt den fehlenden
Host und bildet dessen Storage-Box-Ressourcen vollständig ab: Boxen, Typen,
Actions, Subaccounts und Snapshots, einschließlich CLI, Mock-Fixtures und POD.

Der Maintainer hat den ursprünglich vorgeschlagenen Erstrundenumfang ausdrücklich
erweitert: Subaccounts, Snapshot-Verwaltung und Storage-Label-Kommandos werden
**nicht vertagt**. Pagination bleibt kompatibel: `list()` liefert eine Seite,
`list_all()` wird additiv ergänzt; CLI-Listen und vollständige lokale Namenssuchen
verwenden `list_all()`.

## API-Grundlage

Offizielle OpenAPI-Beschreibung, im ursprünglichen Entwurf am 2026-09-08 geprüft:
`https://docs.hetzner.cloud/hetzner.spec.json`, OpenAPI 3.1.2, Titel „Hetzner API“,
Server `https://api.hetzner.com/v1`. Vor der Implementierung sind konkrete
Request-Felder und CLI-Optionen nochmals gegen diese offiziellen Quellen zu prüfen.
Keine Gegenprobe gegen echte Infrastruktur.

### Authentifizierung und Fehler

Bearer-Token aus einem Hetzner-Console-Projekt, beschafft unter Security → API
Tokens. Dieselbe Beschaffungsanweisung steht in der Cloud-Spezifikation; auch
Hetzners Ansible-Modul `hetzner.hcloud.storage_box` verwendet denselben
`api_token`/`HCLOUD_TOKEN` und einen eigenen `api_endpoint_hetzner`.

Die Distribution verwendet entsprechend ihrer bestehenden Cloud-Konvention
`HETZNER_API_TOKEN`, nicht `HCLOUD_TOKEN` und keine neue Storage-Variable.
Robots Basic Auth ist hier nicht beteiligt.

Fehlerform: `{"error":{"code","message","details"}}`, wie Cloud. Bestehendes
`Role::HTTP::_parse_response` ist wiederzuverwenden.

### Endpunkte

| Pfad | Methoden | Antwort |
|---|---|---|
| `/storage_boxes` | GET, POST | `{storage_boxes, meta}` · `{storage_box, action}` |
| `/storage_boxes/{id}` | GET, PUT, DELETE | `{storage_box}` · `{storage_box}` · `{action}` |
| `/storage_boxes/{id}/folders` | GET | `{folders: [String]}` |
| `/storage_boxes/actions` | GET | `{actions, meta}` |
| `/storage_boxes/actions/{id}` | GET | `{action}` |
| `/storage_boxes/{id}/actions` | GET | `{actions, meta}` |
| `/storage_boxes/{id}/actions/{action_id}` | GET | `{action}`, deprecated; nicht zum Polling benutzen |
| `/storage_boxes/{id}/actions/change_protection` | POST | `{action}` |
| `/storage_boxes/{id}/actions/change_type` | POST | `{action}` |
| `/storage_boxes/{id}/actions/reset_password` | POST | `{action}` |
| `/storage_boxes/{id}/actions/update_access_settings` | POST | `{action}` |
| `/storage_boxes/{id}/actions/rollback_snapshot` | POST | `{action}` |
| `/storage_boxes/{id}/actions/enable_snapshot_plan` | POST | `{action}` |
| `/storage_boxes/{id}/actions/disable_snapshot_plan` | POST | `{action}` |
| `/storage_boxes/{id}/subaccounts` | GET, POST | `{subaccounts}` · `{subaccount, action}` |
| `/storage_boxes/{id}/subaccounts/{sid}` | GET, PUT, DELETE | `{subaccount}` · `{subaccount}` · `{action}` |
| `/storage_boxes/{id}/subaccounts/{sid}/actions/change_home_directory` | POST | `{action}` |
| `/storage_boxes/{id}/subaccounts/{sid}/actions/reset_subaccount_password` | POST | `{action}` |
| `/storage_boxes/{id}/subaccounts/{sid}/actions/update_access_settings` | POST | `{action}` |
| `/storage_boxes/{id}/snapshots` | GET, POST | `{snapshots}` · `{snapshot, action}` |
| `/storage_boxes/{id}/snapshots/{sid}` | GET, PUT, DELETE | `{snapshot}` · `{snapshot}` · `{action}` |
| `/storage_box_types` | GET | `{storage_box_types, meta}` |
| `/storage_box_types/{id}` | GET | `{storage_box_type}` |

Der deprecated Einzelaktionspfad wurde laut Spezifikation am 2026-04-30
abgekündigt. Polling verwendet immer `/storage_boxes/actions/{id}`; ein globales
`/actions/{id}` existiert für diesen Host nicht.

### Entity-Felder und Pflichtangaben

- StorageBox: `id`, `name`, `storage_box_type`, `location`, `access_settings`,
  `snapshot_plan` (nullable), `protection`, `labels`, `status`, `username`
  (nullable), `server` (nullable), `system` (nullable), `stats`, `created`.
- Subaccount: `id`, `storage_box`, `name`, `home_directory`, `access_settings`,
  `description`, `labels`, `username`, `server`, `created`.
- Snapshot: `id`, `storage_box`, `name`, `description`, `labels`, `stats`,
  `is_automatic`, `created`.
- StorageBoxType: `id`, `name`, `description`, `snapshot_limit` (nullable),
  `automatic_snapshot_limit` (nullable), `subaccounts_limit`, `size`, `prices`,
  `deprecation` (nullable).

Create-Pflichtfelder: Box `storage_box_type`, `location`, `name`, `password`;
Subaccount `home_directory`, `password`; Snapshot keine Pflichtfelder.
Nullable Werte bleiben `undef`; Datenrepräsentation und Accessoren folgen den
vorhandenen Cloud-Entities, einschließlich vollständiger Rohdaten über `data()`.

### Actions und Rückgabevertrag

Das Action-Schema entspricht Cloud: `id`, `command`, `status`, `progress`,
`started`, `finished` (nullable), `resources`, `error` (nullable mit code/message).
Status: running/success/error.

- Create liefert das Entity mit erforderlicher `->action`.
- Update liefert das Entity, **keine erfundene Action**.
- Delete liefert eine Action; die API antwortet HTTP 201 mit `{action}`, nicht 204.
- POST-Action-Endpunkte liefern `WWW::Hetzner::Action`.
- Keine Storage-Operation liefert `next_actions`, plural `actions` beim Create
  oder Sidecar-Daten. Vorhandene optionale gemeinsame Attribute dürfen leer bleiben.
- Passwort-Resets nehmen das Passwort als Eingabe; sie liefern keines zurück.
- Die Bibliothek wartet nicht automatisch. Die CLI wartet nach bestehendem Muster;
  `--no-wait` schaltet dies ab.

### Pagination und Rate Limit

`page`/`per_page` und `meta.pagination` entsprechen Cloud. Default 25, Maximum 50;
Metadaten: page, per_page, previous_page, next_page, last_page, total_entries,
zusätzlich Link-Header. Der proseartige `page_size`-Verweis der API-Doku widerspricht
den maschinenlesbaren Parametern; maßgeblich ist `per_page`.

Paginierung gilt für Boxen, Typen und beide Action-Listen. Subaccounts und Snapshots
haben laut Spezifikation weder entsprechende Parameter noch `meta`.

`list()` bleibt ein Seitenabruf. `list_all()` nutzt den gemeinsamen Helfer aus #12:
Start bei erster bzw. ausdrücklich gesetzter `page`, `per_page` als Seitengröße,
Filter/Sortierung unverändert auf jeder Folgeseite, keine Mutation der Aufrufparameter.
Fehlende Metadaten bedeuten eine vollständige Einzelantwort; wiederholte oder
ungültige Folgeseiten und Fehler auf späteren Seiten werden laut gemeldet.
Nicht paginierte Unterlisten erhalten keine erfundenen Query-Parameter.

Beide APIs nennen 3600 Requests/Stunde und Projekt. Ob sie das Kontingent teilen,
ist nicht dokumentiert. Kein spekulativer Backoff oder Rate-Limit-Umbau.

## Entscheidungen

### E1 — Eigener Storage-Client

`WWW::Hetzner::Storage` wird Geschwister von Cloud und Robot, erreichbar über
`$hetzner->storage`. Ein Client besitzt eine `base_url`; ein Cloud-Anbau müsste
sie umbiegen oder den IO-Seam umgehen. Beides wird vermieden. Kein generischer
Multi-Host-Client und keine vorsorgliche Abstraktion für mögliche weitere Dienste.

### E2 — Gemeinsamer Env-Default, explizite Client-Konfiguration

Storage verwendet `token` mit Default `$ENV{HETZNER_API_TOKEN}` und überschreibbare
`base_url` mit Default `https://api.hetzner.com/v1`. Keine neue Env-Variable.
Die Dachklasse erhält kein zusätzliches Token-Attribut: ihre Clients lesen jeweils
den bestehenden Env-Default. Individuelle Tokens können am jeweiligen Client gesetzt
werden. Die CLI baut Cloud und Storage aus ihrer vorhandenen `--token`-Option.

Fehlende Authentifizierung wird wie bei Cloud früh mit hilfreichem Storage-Hinweis
abgewiesen, bevor der Request ausgeführt wird.

### E3 — Gemeinsamen HTTP-/IO-Seam erhalten

Storage konsumiert `Role::HTTP`; der Pfad bleibt `_build_request` → `io->call`
→ `_parse_response`. Keine Storage-HTTP-Rolle und kein direkter LWP-Zugriff.

Die separaten Tickets #11/#13 korrigieren Form-Encoding für Robot und URI-Kodierung
für alle Clients. Storage verwendet deren JSON/Bearer-Default unverändert. Die
Request-/Response-Signaturen und Objektformen bleiben erhalten. Async-Folgetickets
zur Seam-Regression werden auf dem Schwesterboard gepflegt, ohne dessen Code hier
zu bearbeiten. Eine Async-Storage-Erweiterung ist nicht Teil dieses Vorhabens.

### E4 — Neutrale Action-Bausteine

Vorgelagert in #10 freigegeben und umgesetzt:

| vorher | nachher |
|---|---|
| `WWW::Hetzner::Cloud::Action` | `WWW::Hetzner::Action` |
| `WWW::Hetzner::Cloud::Role::HasAction` | `WWW::Hetzner::Role::HasAction` |
| `WWW::Hetzner::Cloud::Role::HasActions` | `WWW::Hetzner::Role::HasActions` |

Keine Rückwärtsaliases: diese Klassen waren nicht veröffentlicht. Cloud::API::Actions
bleibt Cloud-spezifisch. Keine zweite Action-Klasse und keine duplizierte Poll-Logik.

Die gemeinsamen Wrapper erhalten in #5 einen überschreibbaren Poll-Pfad:
Cloud `/actions`, Storage `/storage_boxes/actions`. Dies gilt für direkt gelieferte
Actions und die Create-Actions von Boxen, Subaccounts und Snapshots.

### E5 — CLI unter hcloud.pl storage-box

Kein drittes Binary. `WWW::Hetzner::CLI` folgt der offiziellen hcloud-CLI, deren
Storage-Box-Zweig seit 1.61.0 existiert. Der separate Robot-Einstieg bleibt unberührt.

Box-Kommandos: list, describe, create, update, delete, change-type, reset-password,
enable-protection, disable-protection, enable-snapshot-plan, disable-snapshot-plan,
rollback-snapshot, update-access-settings, folders, add-label, remove-label.
Dazu Untergruppen snapshot und subaccount für deren CRUD und Action-Operationen;
konkrete Optionennamen anhand der offiziellen CLI-Dokumentation ausrichten.
Storage-Label-Änderungen erhalten alle anderen Labels; kein Label-Umbau für sämtliche
Cloud-Ressourcen.

Mechanik: `CLI::Cmd::StorageBox`, `StorageBox::Cmd::*`, Unterbäume für Snapshot und
Subaccount, vorhandene Alias-Tabelle und custom_help in `bin/hcloud.pl`, eigener
storage-Accessor in `CLI.pm`. Mutierende Action-Pfade nutzen `WaitsForAction`.

### E6 — MockIO und flache Fixtures

`t/lib/Test/WWW/Hetzner/Mock.pm` erhält `mock_storage` nach `mock_cloud`/`mock_robot`,
mit eigener base_url und test-token. Die in #11/#13 erweiterte MockIO-Schnittstelle
wird wiederverwendet: Query-Inspektion, Content-Type-gerechte Bodies und originale
Requests für unabhängige RAW-Assertions. Keine Umgestaltung zu einer generischen
Fabrik; unterschiedliche Hosts erhalten getrennte MockIO-Instanzen.

Flache Fixtures unter `t/fixtures/`, Werte aus den offiziellen API-Beispielen:
`storage_boxes_{list,get,create,action,folders}.json`,
`storage_box_actions_{get,list}.json`, `storage_box_types_{get,list}.json`,
entsprechende `storage_box_subaccounts_*` und `storage_box_snapshots_*`.
Keine erfundenen Response-Felder und kein neues Fixture-Unterverzeichnis.

### E7 — Vollständiger Umfang dieser Umsetzung

- Storage-Client, Boxen, Typen, Actions.
- Subaccounts mit CRUD und den drei dokumentierten Actions.
- Snapshots mit CRUD; Snapshot-Plan/Rollback bleiben Box-Actions.
- Vollständiger entsprechender CLI-Baum einschließlich Storage-Labels.
- Fixtures, API-/Entity-/CLI-Tests, POD und Navigation.
- Pagination und Query-Encoding über die eigenständigen Tickets #12/#13.

Keine Vertagung der Unterressourcen in neue Tickets. Nicht enthalten: S3/Object
Storage, Async-Storage, spekulative zusätzliche API-Ressourcen, Release.

## Architektur und betroffener Bestand

Neue Module unter `lib/WWW/Hetzner/`:

- `Storage.pm`.
- `Storage/API/{StorageBoxes,StorageBoxTypes,Actions,Subaccounts,Snapshots}.pm`.
- `Storage/{StorageBox,StorageBoxType,Subaccount,Snapshot}.pm`.
- `CLI/Cmd/StorageBox.pm`, `CLI/Cmd/StorageBox/Cmd/*.pm` und die Unterbäume.

Mesh nach vorhandener Eins-zu-eins-Konvention:

| Ressourcenwurzel | Accessor | Controller | Entity |
|---|---|---|---|
| storage_boxes | `$storage->storage_boxes` | API::StorageBoxes | StorageBox |
| storage_box_types | `$storage->storage_box_types` | API::StorageBoxTypes | StorageBoxType |
| storage_boxes/actions | `$storage->actions` | API::Actions | WWW::Hetzner::Action |
| storage_boxes/{id}/actions | `$box->actions` | API::Actions (storage_box_id gesetzt) | WWW::Hetzner::Action |
| subaccounts | `$box->subaccounts` | API::Subaccounts | Subaccount |
| snapshots | `$box->snapshots` | API::Snapshots | Snapshot |

Unterressourcen-Controller tragen storage_box_id nach `Cloud/API/RRSets.pm`;
Entity-Zugriff folgt `Cloud/Zone.pm`. Der Actions-Controller verwendet dasselbe
Muster: optionales storage_box_id bindet ausschließlich list/list_all an die Box;
get($action_id) und Polling verwenden auch dort den globalen unterstützten Pfad.
Ein zusätzlicher Wrapper für den deprecated Einzelaktionspfad wird nicht eingeführt.
Kürzere erfundene Namen wie `$storage->boxes` werden nicht eingeführt.

Bestehende Dateien: `lib/WWW/Hetzner.pm`, `lib/WWW/Hetzner/CLI.pm`,
`lib/WWW/Hetzner/Role/HasActions.pm`, `bin/hcloud.pl`,
`t/lib/Test/WWW/Hetzner/Mock.pm`, `t/basic.t`, `Changes`, README und POD-Navigation.
Alle neuen Module müssen über L<> von WWW::Hetzner erreichbar sein.

## Abnahme und Tests

Ausschließlich netzfreie Mock-Tests; sleeper injizieren, kein echtes Warten.

- Client: richtiger Host, Bearer-Auth, explizite Tokens/URL und fehlender Token.
- Boxen/Typen: list/get/list_all/get_by_name, vollständige und nullable Attribute,
  Create-Pflichtfelder, Update-Entity, Delete-Action, Folders als String-Arrayref.
- Alle sieben Box-Actions: Pfad, Body und Action-Rückgabe.
- Subaccounts: CRUD, alle drei Actions, richtige Box-/Subaccount-ID, Passwort als
  Eingabe, Create-Action und Delete-Action.
- Snapshots: CRUD, optionale Create-Felder, richtige verschachtelte IDs,
  Create-Action und Delete-Action; Box-Snapshot-Plan und Rollback separat.
- Action-Polling für alle Rückgabewege gegen `/storage_boxes/actions/{id}`,
  niemals global `/actions` oder deprecated Pfade; running → success, API-Fehler,
  Action-Fehler und Timeout.
- Pagination für Boxen, Typen und Action-Listen mit mehreren Seiten;
  Unterressourcen ohne erfundene Pagination.
- CLI: jedes neue echte execute(), valide Optionen und Request-Weitergabe,
  JSON decodierbar, Tabellen über Accessoren, Label-Erhalt, Standard-Wait und
  `--no-wait`, Fehlerweitergabe. Aliases/Hilfe einschließlich Untergruppen prüfen.
- Fixtures aus offiziellen Beispielen; RAW-Requests unabhängig vom Mock-Dekoder
  prüfen, wo die Kodierung den Vertrag trägt.
- Neue Module laden, POD-Syntax und vollständiger Linkgraph, Gesamtsuite,
  `dzil build` und `dzil test`. Übersprungene Liveintegration ausdrücklich melden.

`Changes` unter `{{$NEXT}}` beschreibt den tatsächlichen neuen Umfang. Keine
Versions-/Release-Aktion aus dieser Spezifikation ableiten.
