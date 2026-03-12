# WWW-VastAI

Perl client for the Vast.ai REST APIs.

## Installation

```bash
cpanm WWW::VastAI
```

## Coverage

- marketplace offers
- instances and lifecycle actions
- templates
- volumes
- SSH keys and API keys
- current user and env vars
- invoices
- serverless endpoints and workergroups

## Basic usage

```perl
use WWW::VastAI;

my $vast = WWW::VastAI->new(
    api_key => $ENV{VAST_API_KEY},
);

my $offers = $vast->offers->search(
    limit    => 5,
    verified => { eq => \1 },
    rentable => { eq => \1 },
    rented   => { eq => \0 },
    gpu_name => { in => ['RTX_4090', 'RTX_5090'] },
);

my $instance = $offers->[0]->create_instance(
    image   => 'vastai/base-image:@vastai-automatic-tag',
    disk    => 32,
    runtype => 'ssh',
);

my $templates = $vast->templates->list(
    select_filters => { use_ssh => { eq => \1 } },
);
```

## Tests

Normal test suite:

```bash
prove -lr t
```

No-cost live test:

```bash
VAST_LIVE_TEST=1 VAST_API_KEY=... prove -lv t/90-live-vastai.t
```

Cost-incurring live tests:

```bash
VAST_LIVE_TEST=1 VAST_LIVE_ALLOW_COST=1 VAST_API_KEY=... \
  prove -lv t/91-live-vastai-cost.t
```

Volume lifecycle test under the same cost gate:

```bash
VAST_LIVE_TEST=1 VAST_LIVE_ALLOW_COST=1 VAST_API_KEY=... \
  prove -lv t/92-live-vastai-volume.t
```

## Documentation

The main module POD covers the client entry point. Resource-specific details
live in the API and entity classes for offers, instances, templates, volumes,
account resources, endpoints, and workergroups.
