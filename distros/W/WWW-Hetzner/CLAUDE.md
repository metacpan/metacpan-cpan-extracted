# WWW-Hetzner

Perl client for Hetzner APIs (Cloud, Robot).

## Hetzner APIs

**Cloud API** (`api.hetzner.cloud`)
- Servers, Volumes, Networks, Firewalls, Load Balancers
- Floating IPs, Primary IPs, Certificates, Placement Groups
- SSH Keys, Images, Server Types, Locations, Datacenters
- **DNS Zones und Records** - DNS ist Teil der Cloud API

**Robot API** (`robot-ws.your-server.de`)
- Dedicated Servers, IPs, SSH Keys, Reset, Traffic

## Build & Test

```bash
dzil build          # Build distribution
dzil test           # Run all tests
prove -lv t/        # Run tests directly
```

## CLI Usage

```bash
# Cloud CLI
hcloud.pl server list
hcloud.pl server create --name test --type cx22 --image debian-12 --location fsn1
hcloud.pl volume create --name data --size 50 --location fsn1
hcloud.pl network create --name mynet --ip-range 10.0.0.0/8
hcloud.pl firewall create --name web-fw
hcloud.pl floating-ip create --type ipv4 --home-location fsn1
hcloud.pl load-balancer create --name lb --type lb11 --location fsn1
hcloud.pl certificate create --name cert --domain example.com

# Robot CLI
hrobot.pl server list
hrobot.pl ip list
hrobot.pl traffic query --from 2024-01-01
```

## Structure

```
lib/WWW/Hetzner.pm              # Main entry point
lib/WWW/Hetzner/Cloud.pm        # Cloud API client
lib/WWW/Hetzner/Cloud/API/      # API modules (Servers, Volumes, Networks, etc.)
lib/WWW/Hetzner/Cloud/*.pm      # Entity classes (Server, Volume, Network, etc.)
lib/WWW/Hetzner/Robot.pm        # Robot API client
lib/WWW/Hetzner/Robot/API/      # Robot API modules
lib/WWW/Hetzner/CLI.pm          # Cloud CLI main
lib/WWW/Hetzner/CLI/Cmd/        # CLI subcommands
lib/WWW/Hetzner/Robot/CLI.pm    # Robot CLI main
lib/WWW/Hetzner/Robot/CLI/Cmd/  # Robot CLI subcommands
bin/hcloud.pl                   # Cloud CLI executable
bin/hrobot.pl                   # Robot CLI executable
t/                              # Tests with mock fixtures in t/fixtures/
```

## Cloud API Resources

| Resource | API Class | Entity Class | CLI |
|----------|-----------|--------------|-----|
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

## Tech

- **Moo** for OOP
- **MooX::Cmd** + **MooX::Options** for CLI
- **Log::Any** for logging
- **Dist::Zilla** with `[@Author::GETTY]`
