# Design: Cloud Actions

- Ticket: karr #2 (Board `WWW-Hetzner`)
- Datum: 2026-09-06
- Status: genehmigt, Implementierungsplan ausstehend

## Problem

Die Hetzner Cloud API antwortet auf jeden mutierenden Aufruf mit einer Action —
einem asynchronen Vorgang mit eigenem Status. `WWW::Hetzner` wirft diese
Information heute weg oder reicht sie unbearbeitet durch:

- `Cloud/API/Servers.pm:208` gibt nur `$result->{server}` zurück; `action` und
  `next_actions` fallen unter den Tisch.
- `Cloud/API/Servers.pm:234` und die übrigen 37 Aktionsmethoden geben den rohen
  dekodierten Hashref `{action => {...}}` durch.
- `Role/HTTP.pm:200` croakt ausschliesslich bei HTTP-Status ausserhalb 2xx. Eine
  fehlgeschlagene Action kommt aber als **HTTP 201 mit `action.status ==
  "error"`** und läuft damit vollständig am Fehlerpfad vorbei.

Folge: Ein `create`, dessen Action scheitert, ist von einem erfolgreichen nicht
zu unterscheiden. `CLI/Cmd/Server/Cmd/Poweron.pm:20` druckt `"Server powered
on."`, bevor die Action überhaupt begonnen hat.

Das einzige Warten ist `wait_for_status` (`Cloud/API/Servers.pm:488`). Es pollt
den Server-Status, nicht die Action, existiert nur für Server und sagt nichts
darüber, warum ein Vorgang scheiterte.

## Entscheidungen

Vier Festlegungen, jeweils mit dem Grund, der sie getragen hat.

### E1 — Die Bibliothek wartet nicht ungefragt

Mutierende Aufrufe geben ein `Action`-Objekt zurück und schlafen nicht. Wer
warten will, ruft `->wait`.

Grund: Eine Bibliothek, die in `create` heimlich schläft, ist überraschend, und
`wait_for_status` ist der Präzedenzfall für *bewusst angefordertes* Warten.

Verworfene Alternative: blockierend per Default mit `wait => 0` als Opt-out. Das
löst das Fehlerproblem zwar ohne Zutun des Aufrufers, ändert aber das
Zeitverhalten jedes bestehenden Aufrufs.

Ausdrücklich **nicht** tragend war die anfangs angeführte Parität mit
`p5-net-async-hetzner`. Die Prüfung ergab: `Net::Async::Hetzner::Cloud`
implementiert `Role::IO` nicht, sondern instanziiert intern ein
`WWW::Hetzner::Cloud` und borgt sich daraus nur `_build_request` und
`_parse_response` (`Net/Async/Hetzner/Cloud.pm:100` und `:103`). Es gibt dort
weder Controller noch Entities — also auch keine Objektform, die in Parität zu
halten wäre.

### E2 — Das blockierende Warten gehört in die CLI

`hcloud.pl` wartet per Default und bietet `--no-wait`. Dort sitzt der Anwender,
der das Ergebnis sehen will; die Bibliothek bleibt ehrlich.

### E3 — `create` gibt weiterhin das Entity zurück

Das Entity trägt die erzeugende Action als Attribut `action`, die Folgeaktionen
als `next_actions`. Bestehende `create`-Aufrufe brechen nicht.

Verworfen: ein eigenes `Result`-Objekt mit `->server`/`->action` (bricht jeden
`create`-Aufruf über alle Ressourcen hinweg) und eine `wantarray`-Rückgabe
(kontextabhängige Rückgaben sind eine Fehlerquelle, die man später bereut).

### E4 — Injizierbarer Sleeper

Der Client bekommt ein `sleeper`-Attribut, Default `sub { sleep $_[0] }`. Tests
schieben eine Zähl-Closure hinein.

Grund: Intervall- **und** Timeout-Pfad werden ohne Wanduhr testbar, und die
Anzahl der Polls ist prüfbar. Ein Timeout-Test, der echte Sekunden braucht, ist
ein flaky Test.

### E5 — Action-Methoden mit Sidecar-Daten: die Action trägt sie

Fünf Server-Action-Methoden liefern laut `cloud.spec.json` Nutzdaten *neben*
`action`, die bei der pauschalen Umstellung auf „gib die Action zurück"
verloren gingen:

| Methode | Sidecar |
|---|---|
| `enable_rescue`, `rebuild`, `reset_password` | `root_password` |
| `request_console` | `password`, `wss_url` |
| `create_image` | `image` (Endpunkt in dieser Distribution noch nicht implementiert — bekommt `result` automatisch, sobald der Controller-Method dazukommt) |

Festlegung (Maintainer, 2026-09-07): Diese Methoden geben weiterhin eine
`Action` zurück, die die Sidecar-Felder trägt. Die `Action` bekommt ein
Attribut `result` (Hashref, Default `{}`) mit den Zusatzfeldern, plus getippte
Bequemlichkeits-Leser (`root_password`, `image`, `wss_url`, `password`), die
aus `result` lesen und `undef` liefern, wenn das Feld fehlt.

Grund: Der einheitliche Action-Rückgabevertrag bleibt (jeder mutierende Aufruf
gibt eine `Action`), es geht nichts verloren, und die Sidecar-Daten sind am
Objekt auffindbar. Verworfen: ein eigenes Result-Objekt mit `->action` (wie
E3) — konzeptuell sauber, aber eigene Rückgabeform pro Methode und mehr Code,
ohne Mehrwert gegenüber dem `result`-Attribut.

Folge: Die CLI-Kommandos, die diese Daten anzeigen (`server rescue`,
`reset-password`, `rebuild`, `create-image`), lesen sie über den neuen Zugriff
(`$action->root_password` bzw. `$action->result`). Das behebt zugleich karr #6.

## Architektur

### Neue Klassen

**`WWW::Hetzner::Cloud::Action`** — Entity nach dem Muster von
`WWW::Hetzner::Cloud::Server`: `client` als `weak_ref`, dazu die Attribute
`id`, `command`, `status`, `progress`, `started`, `finished`, `resources`,
`error`.

| Methode | Verhalten |
|---|---|
| `is_running` / `is_success` / `is_error` | Status-Prädikate |
| `error_message` | `error.message` oder `undef` |
| `refresh` | Neu laden über `poll_path` |
| `wait(%opts)` | Pollt bis Endzustand |
| `data` | Rohdaten, wie bei den übrigen Entities |

`wait` nimmt `interval` (Default 1) und `timeout` (Default 120, konsistent zu
`wait_for_status`). Es croakt bei `status eq 'error'` mit der API-Meldung und
bei Zeitüberschreitung mit Action-Id und Kommando.

**`WWW::Hetzner::Cloud::API::Actions`** — Controller mit `get($id)` und
`list(%params)`.

### Der Poll-Pfad

Die `Action` erhält ihren Poll-Pfad vom erzeugenden Controller als Attribut
`poll_path`. `refresh` hängt `/$id` daran.

Default ist der globale Pfad `/actions` (geklärt: nicht abgekündigt, siehe „Vor
der Implementierung geklärt"). `poll_path` bleibt als Attribut trotzdem
erhalten: es macht die Ressourcen-Variante `/{resource}/actions/{id}` zu einer
Zeile pro Controller statt eines Umbaus, falls sie je gebraucht wird.

### Neue Rollen

**`WWW::Hetzner::Cloud::Role::HasActions`** — liefert `_wrap_action`, konsumiert
von den 8 Controllern, die Actions erzeugen. Additiv; die bestehenden
`_wrap`/`_wrap_list` in den Controllern bleiben unangetastet.

**`WWW::Hetzner::Cloud::Role::HasAction`** — liefert Entities die Attribute
`action` und `next_actions`.

Konsumiert von **acht** Entities, deren `create`-Antwort laut offizieller
`cloud.spec.json` ein singular `action` enthält: `Certificate`, `FloatingIP`,
`LoadBalancer`, `PrimaryIP`, `Server`, `Volume`, `PlacementGroup`, `Zone`.

Die frühere Zählung „genau sechs" stammte aus den vorhandenen Fixtures, nicht
aus dem echten Vertrag: die `create`-Fixtures von `PlacementGroup` und `Zone`
sind veraltet und enthalten die Action nicht, die die echte API liefert. Bei
`PlacementGroup` ist `action` nullable (nur ein *managed* Placement-Group löst
eine aus) — `HasAction` muss den `undef`-Fall tragen. Siehe „Vor der
Implementierung geklärt".

`Firewall` ist der Sonderfall: `create` liefert **`actions` im Plural** (eine
Liste), nicht ein einzelnes `action`. `Firewall` konsumiert daher **nicht**
`HasAction`, sondern bekommt ein eigenes Attribut `actions` (Arrayref von
`Action`-Objekten). Der Wrap-Helfer in `HasActions` deckt beide Formen ab.

Nicht konsumiert von `Network`, `RRSet`, `SSHKey` — deren `create`-Antwort
enthält laut Spec keine Action.

`action` ist der Zustand zum Zeitpunkt der Erzeugung — ein Snapshot. Es ist
`ro` und wird von `->refresh` des Entities nicht angefasst, bleibt also als
(dann ggf. veralteter) Erzeugungs-Snapshot erhalten. Das steht so in der POD.

(Korrektur 2026-09-07: Der ursprüngliche Entwurf sagte „nach `->refresh`
`undef`". Das war eine nicht umgesetzte Über-Spezifikation; ein erhaltener
Snapshot ist harmlos und nützlicher als ein Nullen. Die POD dokumentiert die
tatsächliche Behaviour.)

**`WWW::Hetzner::CLI::Role::WaitsForAction`** — liefert die Option `--no-wait`
und einen `handle_action`-Helfer. Es gibt keine CLI-Basisklasse; jedes Kommando
ist eigenständig `MooX::Cmd` plus `MooX::Options`, und `MooX::Options` erlaubt
das Bereitstellen von Optionen aus einer Rolle.

### Sleeper

`sleeper` wird auf `WWW::Hetzner::Role::HTTP` gelegt, nicht auf `Cloud` —
additiv, und `Robot` erbt es für das spätere `boot`-Polling aus karr #4.

`is => 'rw'` mit Default `sub { sleep $_[0] }`, damit Tests es nach dem Bau
setzen können und `mock_cloud` nicht umgebaut werden muss.

## Betroffener Bestand

| Ort | Änderung | Umfang |
|---|---|---|
| `Cloud/API/*.pm` | Aktionsmethoden geben `Action` statt Hashref | 38 Methoden, 8 Dateien |
| `Cloud/*.pm` (Entities) | gespiegelte Aktionsmethoden ebenso | 28 Methoden, 8 Dateien |
| `Cloud/*.pm` (Entities) | `HasAction` konsumieren (singular `action`) | 8 Dateien |
| `Cloud/Firewall.pm` | `actions`-Attribut (Plural-Liste) | 1 Datei |
| `t/fixtures/*_create.json` | veraltete Fixtures an die echte API angleichen | placement_groups, zones, volumes |
| `Cloud.pm` | `actions`-Attribut für den neuen Controller | 1 |
| `CLI/Cmd/**` | `WaitsForAction` konsumieren | mutierende Subcommands |
| `Role/HTTP.pm` | `sleeper`-Attribut | 1 |
| `t/cloud_*.t` | `$result->{action}{command}` wird `$result->action->command` | ca. 6 Dateien |

`wait_for_status` bleibt unverändert; seine POD verweist zusätzlich auf `->wait`.

### Brechende Änderung

Die 66 Aktionsmethoden geben statt `{action => {...}}` ein `Action`-Objekt
zurück. Bei Version 0.100 vertretbar, gehört aber als solche in `Changes`.

Die CLI ist davon nicht betroffen: sie verwirft die Rückgabewerte heute
ohnehin (`CLI/Cmd/Server/Cmd/Poweron.pm:18`).

## Tests

Neu `t/cloud_actions.t`, gegen die Mock-Fixture-Harness, ohne Netz:

1. Entity-Attribute und Prädikate aus der Fixture
2. `refresh` lädt neu
3. `wait` Erfolgspfad: `running` → `running` → `success`
4. `wait` Fehlerpfad: croakt mit der Meldung aus `action.error.message`
5. `wait` Timeout: croakt mit Action-Id und Kommando
6. Poll-Anzahl über den injizierten Sleeper, **ohne eine echte Sekunde**
7. `Firewall`-`create` liefert `actions` (Plural) als Arrayref von `Action`
8. `PlacementGroup`-`create` mit nullable `action`: `undef`-Fall trägt sauber
9. `Volume`-`create` trägt `next_actions` aus der angeglichenen Fixture

Neue Fixtures `actions_get.json` und `actions_list.json` in den Zuständen
`running`, `success` und `error`. Aktions-Fixtures für Ressourcen existieren
bereits (`networks_action.json`, `firewalls_action.json` und weitere).

Die Mock-Harness bleibt unverändert: `Test::WWW::Hetzner::MockIO` akzeptiert
schon Coderef-Handler (`t/lib/Test/WWW/Hetzner/Mock.pm:56`), womit sich eine
Folge wechselnder Antworten für denselben Pfad abbilden lässt.

## Nicht im Umfang

- Robot-Ressourcen (karr #4), Storage Boxes (karr #5), read-only Controller
  (karr #3)
- `_build_request` und `_parse_response` werden **in ihrer Form nicht
  angefasst**. Damit bleibt `p5-net-async-hetzner` unberührt und es braucht kein
  Ticket auf dessen Board. Sollte sich das beim Bauen doch ergeben: anhalten und
  dort ein Ticket anlegen — niemals ein stiller Cross-Repo-Edit.
- Kein Release. Das entscheidet der Maintainer gesondert.

## Vor der Implementierung geklärt

Beide Punkte am 2026-09-07 gegen die offizielle `cloud.spec.json`
(`https://docs.hetzner.cloud/cloud.spec.json`) geprüft, nicht geraten:

1. **Poll-Endpunkt.** Der globale `GET /actions/{id}` ist **nicht abgekündigt**
   (`deprecated: false`), ebenso `GET /{resource}/actions/{id}`. Abgekündigt ist
   nur die alte verschachtelte Form `/{resource}/{id}/actions/{action_id}`. →
   `poll_path` bekommt als Default den globalen Pfad `/actions`; `refresh` hängt
   `/$id` an. Der Controller kann den Wert überschreiben, falls je nötig, aber
   der globale Pfad ist sicher.
2. **Welche `create` liefert eine Action** (Fixture vs. echte API):

   | Ressource | Fixture | echte API |
   |---|---|---|
   | Server, FloatingIP, LoadBalancer, PrimaryIP, Certificate | `action` | `action` |
   | Volume | `action` | `action` + `next_actions` |
   | Firewall | `actions` | `actions` (Plural-Liste) |
   | PlacementGroup | — | `action` (nullable) |
   | Zone | — | `action` |
   | Network, RRSet, SSHKey | — | — |

   Konsequenz (vom Maintainer bestätigt, 2026-09-07): auf die echte API
   korrigieren. `HasAction` auf acht Entities, `Firewall` mit Plural-`actions`,
   und die veralteten Fixtures `placement_groups_create.json`,
   `zones_create.json` sowie das fehlende `next_actions` in
   `volumes_create.json` an die echte API angleichen.
