# Implementation Guide — Testcontainers Perl 5

## Overview

This is a complete, production-ready implementation of Testcontainers for Perl 5. It provides Docker container management for testing, inspired by the [Go reference implementation](https://golang.testcontainers.org/) and using [WWW::Docker](https://github.com/Getty/p5-www-docker) (vendored) as the Docker client.

## What's Implemented

A fully functional Perl library with:

### Core API
- `Testcontainers::run()` — create and start containers with a single function call
- `Testcontainers::Container` — running container wrapper with lifecycle, port mapping, exec, and logs
- `Testcontainers::ContainerRequest` — configuration builder that translates options to Docker API format
- `Testcontainers::DockerClient` — `WWW::Docker` wrapper for pull, create, start, stop, remove, inspect, exec, logs
- `Testcontainers::Labels` — org.testcontainers.* label management with reserved prefix validation

### Wait Strategies
- `Testcontainers::Wait::HostPort` — TCP port listening check via `IO::Socket::INET`
- `Testcontainers::Wait::HTTP` — HTTP endpoint check with `HTTP::Tiny` (fallback to raw socket)
- `Testcontainers::Wait::Log` — Log message matching (string or regex, with occurrence count)
- `Testcontainers::Wait::HealthCheck` — Docker health check polling
- `Testcontainers::Wait::Multi` — Composite strategy (all must pass)
- `Testcontainers::Wait::Base` — `Moo::Role` providing the polling loop

### Pre-Built Modules
- `Testcontainers::Module::PostgreSQL` — `postgres_container()`, DSN/connection string helpers
- `Testcontainers::Module::MySQL` — `mysql_container()`, DSN/connection string helpers
- `Testcontainers::Module::Redis` — `redis_container()`, connection string with optional password
- `Testcontainers::Module::Nginx` — `nginx_container()`, base URL helper

### Container Features
- Port mapping with automatic host port allocation
- Environment variables, labels, command, entrypoint
- Tmpfs mounts, privileged mode, network mode, named networks
- Container exec and log retrieval
- Automatic cleanup via `DEMOLISH`

### Build & CI
- `Module::Build` based build system (`Build.PL`) reading from `cpanfile`
- GitHub Actions CI: lint, unit test (Perl 5.40/5.42 matrix), integration test, gate job
- `perlcritic` severity 4 linting

## Directory Structure

```
testcontainers-perl5/
├── Build.PL                           # Build script (reads cpanfile)
├── cpanfile                           # Dependency declarations
├── lib/
│   ├── Testcontainers.pm              # Main entry point — run(), terminate_container()
│   ├── Testcontainers/
│   │   ├── Container.pm               # Running container wrapper
│   │   ├── ContainerRequest.pm        # Configuration builder
│   │   ├── DockerClient.pm            # WWW::Docker wrapper
│   │   ├── Labels.pm                  # Label management
│   │   ├── Wait.pm                    # Wait strategy factory
│   │   ├── Wait/
│   │   │   ├── Base.pm                # Moo::Role — polling loop
│   │   │   ├── HostPort.pm            # TCP port check
│   │   │   ├── HTTP.pm                # HTTP endpoint check
│   │   │   ├── Log.pm                 # Log message matching
│   │   │   ├── HealthCheck.pm         # Docker health check
│   │   │   └── Multi.pm              # Composite strategy
│   │   └── Module/
│   │       ├── PostgreSQL.pm          # PostgreSQL module
│   │       ├── MySQL.pm               # MySQL module
│   │       ├── Redis.pm               # Redis module
│   │       └── Nginx.pm              # Nginx module
│   └── WWW/
│       ├── Docker.pm                  # Vendored Docker client
│       └── Docker/
│           ├── Container.pm           # Container API
│           ├── ContainerExec.pm       # Exec API
│           ├── ContainerExecStart.pm  # Exec start
│           ├── Image.pm               # Image API
│           ├── Network.pm             # Network API
│           ├── Request.pm             # HTTP request handler
│           ├── System.pm              # System info API
│           └── Volume.pm              # Volume API
├── t/
│   ├── 01-load.t                      # Module loading
│   ├── 02-container-request.t         # ContainerRequest tests
│   ├── 03-wait-strategies.t           # Wait strategy tests
│   ├── 04-integration.t              # Integration tests (Docker)
│   ├── 05-modules.t                  # Module tests (Docker)
│   ├── 06-basic.t                    # WWW::Docker basic tests
│   ├── 07-system.t                   # System info tests
│   ├── 08-version.t                  # Version tests
│   ├── 09-containers.t              # Container API tests
│   ├── 10-images.t                  # Image API tests
│   ├── 11-networks.t               # Network API tests
│   ├── 12-volumes.t                # Volume API tests
│   ├── fixtures/                    # Test fixtures
│   └── lib/                         # Test helper modules
└── .github/
    └── workflows/
        └── ci.yml                     # CI pipeline
```

## Key Architecture Decisions

### 1. Functional API (`run()`) over OO Constructor

Inspired by Go's `testcontainers.Run(ctx, req)`. A single function call creates, starts, and waits for a container:

```perl
my $container = run('nginx:alpine',
    exposed_ports => ['80/tcp'],
    wait_for      => Testcontainers::Wait::for_listening_port('80/tcp'),
);
```

### 2. Moo for Lightweight OO

All classes use [Moo](https://metacpan.org/pod/Moo) — fast, lightweight, and compatible with Moose if needed. `Moo::Role` provides shared behaviour (wait strategy base, delegation).

### 3. Vendored WWW::Docker

The Docker client is vendored directly into `lib/WWW/` because the upstream [p5-www-docker](https://github.com/Getty/p5-www-docker) is unmaintained. This avoids an external dependency and allows fixes.

### 4. Role-Based Wait Strategies

`Testcontainers::Wait::Base` is a `Moo::Role` that provides the `wait_until_ready()` polling loop. Each strategy implements `check($container)` returning true/false. The `Multi` strategy composes multiple strategies.

### 5. Labels Specification

Following the Testcontainers specification, containers are labeled with `org.testcontainers.*` metadata. The `Labels` module:
- Generates a session ID for container grouping
- Applies default labels (lang, version, session ID)
- Validates user labels (rejects reserved prefix)
- Provides `_internal_labels` bypass for framework modules

### 6. Automatic Cleanup

`Testcontainers::Container::DEMOLISH` ensures containers are stopped and removed when the Perl object goes out of scope, preventing leaked containers in tests.

## CI Pipeline

The GitHub Actions pipeline has 4 jobs:

1. **lint** — `perlcritic --severity 4` on all source files
2. **test-unit** — Matrix: Perl 5.40, 5.42 — runs non-Docker tests
3. **test-integration** — Runs with Docker, `TESTCONTAINERS_LIVE=1`
4. **ci-success** — Gate job, requires all above to pass

## Future Enhancements

- Ryuk resource reaper for automatic cleanup of orphaned containers
- Container network creation and management API
- Docker Compose support
- Volume mount helpers
- Container file copy (copy-to / copy-from)
- Additional modules: MongoDB, Kafka, Elasticsearch, RabbitMQ
- CPAN distribution packaging
