---
name: vast-ai-perl
description: "WWW::VastAI — Perl client for the Vast.ai GPU cloud API. Usage patterns, architecture, testing."
user-invocable: false
allowed-tools: Read, Grep, Glob
model: sonnet
---

# WWW::VastAI — Perl Client

## Usage

```perl
use WWW::VastAI;

my $vast = WWW::VastAI->new(
    api_key => $ENV{VAST_API_KEY},
);

# Search GPU offers
my $offers = $vast->offers->search(
    limit    => 5,
    verified => { eq => \1 },
    rentable => { eq => \1 },
    gpu_name => { in => ['RTX_4090', 'RTX_5090'] },
);

# Create instance from offer
my $instance = $offers->[0]->create_instance(
    image   => 'pytorch/pytorch:latest',
    disk    => 32,
    runtype => 'ssh',
);

# Instance lifecycle
$vast->instances->list;
$vast->instances->get($id);
$vast->instances->stop($id);
$vast->instances->start($id);
$vast->instances->destroy($id);

# Volumes
$vast->volumes->list;
$vast->volumes->create(name => 'data', disk_space => 50);
$vast->volumes->delete($id);

# Serverless
$vast->endpoints->list;
$vast->endpoints->create(%config);
$vast->workergroups->list;

# Other resources
$vast->templates->list;
$vast->ssh_keys->list;
$vast->api_keys->list;
$vast->user->current;
$vast->env_vars->list;
$vast->invoices->list;
```

## Architecture

Same pattern as WWW::Hetzner — Moo, pluggable IO, operation map.

- **`WWW::VastAI`** — Main client, lazy-builds API accessors
- **`Role::HTTP`** — Bearer auth, JSON encode/decode, `_build_request`/`_parse_response`
- **`Role::IO`** — IO backend interface (`call($request) -> $response`)
- **`LWPIO`** — Default sync backend (LWP::UserAgent)
- **`Role::OperationMap`** — Central route table: operation name → HTTP method + path
- **`API::*`** — Resource controllers (Offers, Instances, Volumes, etc.)
- **`*.pm` entities** — Object classes (Instance, Offer, Volume, etc.)

### Operation Map

All API routes defined in `Role::OperationMap::_build_operation_map`. Three base URLs:

- `v0` → `https://console.vast.ai/api/v0/`
- `v1` → `https://console.vast.ai/api/v1/`
- `run` → `https://run.vast.ai/`

Usage: `$client->request_op('searchOffers', body => \%params)`

### Adding a New API Endpoint

1. Add operation to `Role::OperationMap::_build_operation_map`
2. Create `API::NewResource` with methods that call `request_op`
3. Create entity class if needed (with `new` from API response data)
4. Add accessor to `WWW::VastAI` main class
5. Add tests

## Testing

```bash
prove -l t/                              # Unit tests (mocked)
VAST_LIVE_TEST=1 prove -lv t/90-*.t      # Read-only live tests (free)
VAST_LIVE_TEST=1 VAST_LIVE_ALLOW_COST=1 prove -lv t/91-*.t  # Cost-incurring
```

Mock tests use `WWW::VastAI::Role::IO` — inject a mock IO backend via constructor:

```perl
my $vast = WWW::VastAI->new(api_key => 'test', io => $mock_io);
```

## Tech

- **Moo** + **namespace::clean**
- **JSON::MaybeXS** for JSON
- **Log::Any** for logging
- **LWP::UserAgent** default IO (via LWPIO)
- **Dist::Zilla** with `[@Author::GETTY]`
