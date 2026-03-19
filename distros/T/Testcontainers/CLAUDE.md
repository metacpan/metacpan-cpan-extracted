# CLAUDE.md - Testcontainers for Perl 5

## Project Overview

Testcontainers for Perl 5 - a library for managing Docker containers in tests.
Inspired by the Go reference implementation (https://golang.testcontainers.org/).
Uses WWW::Docker as the Docker client library.

## Architecture

- `lib/Testcontainers.pm` - Main entry point with `run()` function
- `lib/Testcontainers/Container.pm` - Running container wrapper
- `lib/Testcontainers/ContainerRequest.pm` - Container configuration
- `lib/Testcontainers/DockerClient.pm` - WWW::Docker wrapper
- `lib/Testcontainers/Labels.pm` - Label management (org.testcontainers.*)
- `lib/Testcontainers/Wait.pm` - Wait strategy factory
- `lib/Testcontainers/Wait/*.pm` - Wait strategy implementations
- `lib/Testcontainers/Module/*.pm` - Pre-built container modules
- `lib/WWW/Docker.pm` - Vendored Docker client
- `lib/WWW/Docker/*.pm` - Vendored Docker client components

## Test Architecture

- `t/01-load.t` - Module loading (no Docker)
- `t/02-container-request.t` - ContainerRequest unit tests (no Docker)
- `t/03-wait-strategies.t` - Wait strategy unit tests (no Docker)
- `t/04-integration.t` - Integration tests (requires Docker, TESTCONTAINERS_LIVE=1)
- `t/05-modules.t` - Module integration tests (requires Docker, TESTCONTAINERS_LIVE=1)
- `t/06-basic.t` through `t/12-volumes.t` - WWW::Docker unit tests (no Docker)

## Running Tests

```bash
# Unit tests only
prove -l t/01-load.t t/02-container-request.t t/03-wait-strategies.t

# All tests including integration (requires Docker)
TESTCONTAINERS_LIVE=1 prove -l t/
```

## Key Dependencies

- Perl 5.40+
- Moo (object system)
- WWW::Docker (vendored Docker client)
- Log::Any (logging)
- HTTP::Tiny (optional, for HTTP wait strategy)
