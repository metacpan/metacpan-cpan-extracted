---
name: www-hetzner-core
description: "Architecture, vocabulary and invariants of the WWW::Hetzner distribution — the sync Perl client for Hetzner's Cloud and Robot APIs, its pluggable IO transport, the API/entity/CLI mesh, and the mock-fixture test harness. Load when implementing, refactoring, testing or documenting anything in p5-www-hetzner."
user-invocable: false
allowed-tools: Read, Grep, Glob
model: sonnet
---

# WWW::Hetzner — synchronous Hetzner API client

Perl client for Hetzner's two APIs. `WWW::Hetzner` is the **synchronous** distribution;
the async sibling `Net::Async::Hetzner` (repo `p5-net-async-hetzner`) reuses this
distribution's `_build_request`/`_parse_response` over an IO::Async transport. Anything
touching the request/response contract here has a downstream consumer there.

- **Cloud API** (`api.hetzner.cloud`) — Servers, Volumes, Networks, Firewalls, Load
  Balancers, Floating IPs, Primary IPs, Certificates, Placement Groups, SSH Keys, Images,
  Server Types, Locations, Datacenters, and **DNS Zones + Records** (DNS lives inside the
  Cloud API, not a separate service).
- **Robot API** (`robot-ws.your-server.de`) — dedicated Servers, IPs, SSH Keys, Reset,
  Traffic. Authenticates with HTTP Basic Auth (MIME::Base64), not a bearer token.

## Tech baseline

- **Moo** for OOP, `namespace::clean`.
- **MooX::Cmd** + **MooX::Options** for the CLIs.
- **Log::Any** for logging.
- **LWP::UserAgent** for the default synchronous HTTP transport (via `LWPIO`).
- **JSON::MaybeXS** for encode/decode; **MIME::Base64** for Robot Basic Auth.
- **Dist::Zilla** with `[@Author::GETTY]` (see the release skills).

## Module layout

```
lib/WWW/Hetzner.pm                 # main entry point
lib/WWW/Hetzner/Cloud.pm           # Cloud API client
lib/WWW/Hetzner/Cloud/API/*.pm     # API controllers (Servers, Volumes, Networks, …)
lib/WWW/Hetzner/Cloud/*.pm         # entity classes (Server, Volume, Network, …)
lib/WWW/Hetzner/Robot.pm           # Robot API client
lib/WWW/Hetzner/Robot/API/*.pm     # Robot API controllers
lib/WWW/Hetzner/Role/HTTP.pm       # HTTP role (_build_request, _parse_response)
lib/WWW/Hetzner/Role/IO.pm         # IO backend interface (requires 'call')
lib/WWW/Hetzner/HTTPRequest.pm     # transport-independent request object
lib/WWW/Hetzner/HTTPResponse.pm    # transport-independent response object
lib/WWW/Hetzner/LWPIO.pm           # default sync IO backend (LWP::UserAgent)
lib/WWW/Hetzner/CLI.pm             # Cloud CLI main            (bin/hcloud.pl)
lib/WWW/Hetzner/CLI/Cmd/           # Cloud CLI subcommands
lib/WWW/Hetzner/Robot/CLI.pm       # Robot CLI main           (bin/hrobot.pl)
lib/WWW/Hetzner/Robot/CLI/Cmd/     # Robot CLI subcommands
```

Three parallel families move together: adding a Cloud resource means an `API::<Name>`
controller, a `<Name>` entity class, and a `CLI/Cmd/<Name>` subcommand tree.

## Cloud API resource mesh

| Resource | API controller | Entity class | CLI command |
|---|---|---|---|
| Servers | API::Servers | Server | server |
| Server Types | API::ServerTypes | ServerType | servertype |
| Images | API::Images | Image | image |
| SSH Keys | API::SSHKeys | SSHKey | sshkey |
| Volumes | API::Volumes | Volume | volume |
| Networks | API::Networks | Network | network |
| Firewalls | API::Firewalls | Firewall | firewall |
| Floating IPs | API::FloatingIPs | FloatingIP | floating-ip |
| Primary IPs | API::PrimaryIPs | PrimaryIP | primary-ip |
| Load Balancers | API::LoadBalancers | LoadBalancer | load-balancer |
| Certificates | API::Certificates | Certificate | certificate |
| Placement Groups | API::PlacementGroups | PlacementGroup | placement-group |
| Locations | API::Locations | Location | location |
| Datacenters | API::Datacenters | Datacenter | datacenter |
| DNS Zones | API::Zones | Zone | zone |
| DNS Records | API::RRSets | RRSet | record |

## IO architecture — the load-bearing seam

HTTP transport is **pluggable** through `WWW::Hetzner::Role::IO`. Every request follows:

1. `_build_request()` — builds an `HTTPRequest` (method, url, headers, content).
2. `io->call($req)` — the IO backend executes it and returns an `HTTPResponse`.
3. `_parse_response()` — decodes JSON, checks for API errors.

The default backend is `LWPIO` (LWP::UserAgent). A custom backend is any class that
`with 'WWW::Hetzner::Role::IO'` and implements `call($req)` — receives an `HTTPRequest`,
returns an `HTTPResponse`. Inject it via the constructor's `io` attribute. This is exactly
the seam `Net::Async::Hetzner` plugs an async transport into, and the seam the test mock
uses — do not bypass it by calling LWP directly from a controller.

## Testing — mock IO, no live calls

Tests never hit the network. They inject the mock IO backend, which matches request routes
against fixture data.

- The backend class is **`Test::WWW::Hetzner::MockIO`**, shipped in
  **`t/lib/Test/WWW/Hetzner/Mock.pm`**; tests write `use lib 't/lib'; use Test::WWW::Hetzner::Mock;`.
- Loading it exports the helpers used throughout the suite:
  - `load_fixture('servers_list')` — reads `t/fixtures/servers_list.json`.
  - `mock_cloud('GET /servers' => $fixture_or_coderef, …)` — a `WWW::Hetzner::Cloud`
    wired to a MockIO with those routes.
  - `mock_robot(…)` — same for `WWW::Hetzner::Robot`.
- A route value is either a decoded fixture (returned as-is) or a `sub { my ($method, $path, %opts) = @_; … }`
  where `$opts{body}` is the decoded request JSON — use the coderef form to assert on what
  was sent or to vary the response.
- Route keys match `"$METHOD $path"` exactly first, then as a regex against the path.
- Fixtures live in `t/fixtures/*.json` (plus `zones_export.txt`), one per API shape.

Test files are one per resource/area: `t/basic.t` (module loading), `t/cloud_*.t` (each
Cloud resource), `t/robot_*.t` (each Robot area), `t/io.t` (HTTPRequest / HTTPResponse /
Role::IO / LWPIO / MockIO), `t/logging.t` (Log::Any), `t/integration_cloud.t`. Run the
whole suite with `prove -lr t/` (recursive — `t/lib/` holds the harness, not tests).

## Related

- `p5-net-async-hetzner` — `Net::Async::Hetzner`, the async client that reuses this
  distribution's request/response logic over IO::Async + Net::Async::HTTP.
