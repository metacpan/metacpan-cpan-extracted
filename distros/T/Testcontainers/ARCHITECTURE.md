# Testcontainers Perl 5 — Architecture

This document describes the internal design and architectural decisions of the library.
For a feature inventory and implementation stats see [PROJECT_SUMMARY.md](PROJECT_SUMMARY.md).
For usage examples and getting-started instructions see [QUICKSTART.md](QUICKSTART.md).

## Design Goals

| Goal | How |
|------|-----|
| Perl-first | Moo OO, roles, functional API, CPAN conventions |
| Simplicity | Single `run()` entry point returns a ready-to-use container |
| Extensibility | Moo roles for wait strategies, factory functions for modules |
| Test-friendly | Works with `Test::More`, automatic cleanup via `DEMOLISH` |
| Go-inspired | API mirrors [Testcontainers for Go](https://golang.testcontainers.org/) where practical |

## Module Dependency Graph

The library has two independent layers with a strict dependency direction:

```
Testcontainers  ──depends on──►  WWW::Docker  ──speaks to──►  Docker Engine
(test API)                       (HTTP client)                  (REST API)
```

**WWW::Docker** is a self-contained Docker API client vendored from [Getty/p5-www-docker](https://github.com/Getty/p5-www-docker). It translates Perl method calls into Docker Engine REST requests over a Unix socket. It knows nothing about test containers, wait strategies, or modules.

**Testcontainers** owns all concepts meaningful to test authors: container lifecycle, wait strategies, pre-built modules, labels, and network management. It delegates all Docker I/O to `WWW::Docker` via the `Testcontainers::DockerClient` wrapper.

## Component Layout

```
┌──────────────────────────────────────────────────────────────────┐
│  Testcontainers module                                           │
│                                                                  │
│  ┌──────────────┐  ┌───────────────────┐  ┌──────────────────┐  │
│  │ Testcontainers│  │ ContainerRequest  │  │   Container      │  │
│  │ ::run()       │──│ (config builder)  │──│ (running wrapper)│  │
│  └──────────────┘  └───────────────────┘  └──────────────────┘  │
│                                                                  │
│  ┌────────────────────────────────────────────────────────────┐  │
│  │  Wait Strategies (Moo::Role based)                         │  │
│  │  HostPort │ HTTP │ Log │ HealthCheck │ Multi               │  │
│  └────────────────────────────────────────────────────────────┘  │
│                                                                  │
│  ┌────────────────────────────────────────────────────────────┐  │
│  │  Modules (factory functions)                               │  │
│  │  PostgreSQL │ MySQL │ Redis │ Nginx                        │  │
│  └────────────────────────────────────────────────────────────┘  │
│                                                                  │
│  ┌──────────────┐  ┌───────────────────┐                        │
│  │ DockerClient │──│   Labels          │                        │
│  │ (wrapper)    │  │ (org.testcontainers│                       │
│  └──────┬───────┘  │  label mgmt)      │                       │
│         │          └───────────────────┘                        │
├─────────┼────────────────────────────────────────────────────────┤
│         ▼                                                        │
│  ┌──────────────────────────────────────────────────────────────┐│
│  │  WWW::Docker (vendored)                                      ││
│  │  Docker.pm │ Request.pm │ Container.pm │ Image.pm │ etc.     ││
│  └──────────────────────────────────────────────────────────────┘│
└──────────────────────────────────────────────────────────────────┘
```

## Key Patterns

### Factory Function API

The primary API is a single exported function rather than an object constructor:

```perl
use Testcontainers qw( run );
use Testcontainers::Wait;

my $container = run('postgres:16-alpine',
    exposed_ports => ['5432/tcp'],
    env           => { POSTGRES_PASSWORD => 'test' },
    wait_for      => Testcontainers::Wait::for_log('ready to accept connections'),
);
```

This mirrors Go's `testcontainers.Run(ctx, req)` pattern. Internally, `run()` builds a `ContainerRequest`, creates the container via `DockerClient`, starts it, and executes the wait strategy.

### Moo-Based Object System

All classes use [Moo](https://metacpan.org/pod/Moo) for lightweight object construction:

- `has` declarations for attributes with defaults and validation
- `Moo::Role` for shared behaviour (e.g., `Testcontainers::Wait::Base`)
- `DEMOLISH` for automatic cleanup (container termination on object destruction)

### Wait Strategy Composition

Wait strategies follow the role pattern:

```perl
package Testcontainers::Wait::HostPort;
use Moo;
with 'Testcontainers::Wait::Base';

sub check {
    my ($self, $container) = @_;
    # Attempt TCP connection, return 1 on success, 0 on failure
}
```

`Testcontainers::Wait::Base` provides the `wait_until_ready($container, $timeout)` polling loop that repeatedly calls `check()` until it returns true or the timeout expires.

`Testcontainers::Wait::Multi` composes multiple strategies — all must pass.

### Module Pattern

Pre-built modules follow a consistent factory pattern:

```perl
package Testcontainers::Module::PostgreSQL;
use Exporter 'import';
our @EXPORT_OK = qw( postgres_container );

sub postgres_container {
    my (%opts) = @_;
    my $container = Testcontainers::run($image,
        exposed_ports    => ['5432/tcp'],
        env              => { POSTGRES_PASSWORD => $password, ... },
        _internal_labels => { 'org.testcontainers.module' => 'postgresql' },
        wait_for         => Testcontainers::Wait::for_log('ready to accept connections',
                               occurrences => 2),
    );
    return Testcontainers::Module::PostgreSQL::Container->new(
        _container => $container, ...
    );
}
```

The inner `::Container` class wraps the base container and adds service-specific methods like `dsn()` and `connection_string()`.

### Labels Specification

`Testcontainers::Labels` centralizes label management:

- `default_labels($session_id)` — returns the standard `org.testcontainers.*` labels
- `merge_custom_labels(\%defaults, \%user_labels)` — merges user labels, rejecting any with the reserved `org.testcontainers` prefix
- `_internal_labels` attribute on `ContainerRequest` — allows framework code (modules) to set reserved-prefix labels without triggering validation

## Container Lifecycle

```
run($image, %opts)
    │
    ├── Build ContainerRequest
    ├── Pull image (unless no_pull)
    ├── Create container (Docker API)
    ├── Start container
    ├── Refresh (get port mappings)
    ├── Execute wait strategy
    │     └── Poll check() until ready or timeout
    └── Return Container object
         │
         ├── host() / mapped_port() / endpoint()
         ├── exec() / logs()
         └── terminate()
              └── Stop + Remove + Volumes
```

## Error Handling

- User-facing errors use `Carp::croak` with descriptive messages.
- Docker communication errors are caught with `eval { }` and logged via `Log::Any`.
- Wait strategy timeouts produce a `croak` with the strategy name and elapsed time.
- Container auto-cleanup in `DEMOLISH` uses `eval` to suppress errors during global destruction.

## Testing Architecture

Tests are organized by scope:

| File | Scope | Docker? |
|------|-------|---------|
| `t/01-load.t` | Module loading | No |
| `t/02-container-request.t` | ContainerRequest unit tests | No |
| `t/03-wait-strategies.t` | Wait strategy unit tests | No |
| `t/04-integration.t` | Full container lifecycle | Yes |
| `t/05-modules.t` | Module integration | Yes |
| `t/06-basic.t` – `t/12-volumes.t` | WWW::Docker client tests | No |

Integration tests guard with:

```perl
plan skip_all => 'Set TESTCONTAINERS_LIVE=1' unless $ENV{TESTCONTAINERS_LIVE};
```

## References

- [Testcontainers for Go](https://golang.testcontainers.org/) — primary inspiration
- [WWW::Docker](https://github.com/Getty/p5-www-docker) — vendored Docker client
- [Moo](https://metacpan.org/pod/Moo) — object system
- [Docker Engine API v1.44](https://docs.docker.com/engine/api/v1.44/) — Docker REST API reference
