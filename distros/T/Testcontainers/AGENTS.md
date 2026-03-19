# AGENTS.md

Guidelines for AI agents working in the **testcontainers-perl5** repository.

## Project Overview

Perl 5 library for managing throwaway Docker containers in tests, inspired by [Testcontainers for Go](https://golang.testcontainers.org/). Uses [WWW::Docker](https://github.com/Getty/p5-www-docker) (vendored) as the Docker client. Functional API via `Testcontainers::run()` with Moo-based internals.

See [ARCHITECTURE.md](ARCHITECTURE.md) for design decisions and component diagrams.
See [PROJECT_SUMMARY.md](PROJECT_SUMMARY.md) for a full feature inventory.

## Build & Test

```bash
perl Build.PL && ./Build        # Build
prove -l t/                     # Run unit tests (no Docker needed for t/01..03, t/06..12)
TESTCONTAINERS_LIVE=1 prove -l t/  # Run all tests including integration (requires Docker)
```

Linting:

```bash
perlcritic --severity 4 lib/    # Check code quality
```

## Code Style

- Perl 5.40+, `use strict; use warnings;` in every file.
- 4-space indentation, ~120-character line limit.
- `snake_case` for subroutines and variables, `PascalCase` for packages.
- All public APIs must have POD documentation (`=head1`, `=func`, `=method`, `=attr`).
- Use Moo for OO (`has`, `with`, `extends`). Use `Moo::Role` for shared behaviour.
- Use `Carp::croak` for user-facing errors, never `die` with raw strings.
- Use `Log::Any` (`$log->debugf(...)`) for debug/trace output.
- Follow the rules in [CONTRIBUTING.md](CONTRIBUTING.md) for commit messages and PR conventions.

## Architecture Rules

- **Module boundary is strict**: `Testcontainers` depends on `WWW::Docker`, never the reverse. `WWW::Docker` must not reference test-container concepts.
- **Roles over base classes**: `Testcontainers::Wait::Base` is a `Moo::Role` consumed by all wait strategies.
- **Factory function pattern**: modules expose a factory function (e.g., `postgres_container()`) that returns a container wrapper object with convenience methods like `connection_string()` and `dsn()`.
- **Labels specification**: `Testcontainers::Labels` manages `org.testcontainers.*` labels. User-supplied labels with the reserved prefix are rejected by `merge_custom_labels()`. Framework-internal labels (like `org.testcontainers.module`) use `_internal_labels` to bypass validation.

See [ARCHITECTURE.md](ARCHITECTURE.md) for diagrams and rationale.

## Key Paths

| Area | Path |
|------|------|
| Build manifest | `Build.PL`, `cpanfile` |
| Main entry point | `lib/Testcontainers.pm` |
| Container wrapper | `lib/Testcontainers/Container.pm` |
| Request builder | `lib/Testcontainers/ContainerRequest.pm` |
| Docker client wrapper | `lib/Testcontainers/DockerClient.pm` |
| Labels specification | `lib/Testcontainers/Labels.pm` |
| Wait strategy factory | `lib/Testcontainers/Wait.pm` |
| Wait strategy impls | `lib/Testcontainers/Wait/*.pm` |
| Pre-built modules | `lib/Testcontainers/Module/*.pm` |
| Vendored Docker client | `lib/WWW/Docker.pm`, `lib/WWW/Docker/*.pm` |
| Unit tests | `t/01-load.t` through `t/12-volumes.t` |
| Integration tests | `t/04-integration.t`, `t/05-modules.t` |
| CI workflows | `.github/workflows/` |

## Common Agent Tasks

### Adding a new container module

1. Create `lib/Testcontainers/Module/MyService.pm` following the existing `PostgreSQL.pm` / `Redis.pm` pattern.
2. Export a factory function (e.g., `myservice_container(%opts)`).
3. Pre-configure: image, default port, environment variables, and a wait strategy.
4. Use `_internal_labels` (not `labels`) for `org.testcontainers.module`.
5. Create an inner container class with convenience methods (e.g., `connection_string()`).
6. Add integration tests in `t/05-modules.t` or a new test file.
7. Update `README.md` with a usage example.

### Adding a new wait strategy

1. Create `lib/Testcontainers/Wait/MyStrategy.pm`.
2. `use Moo; with 'Testcontainers::Wait::Base';` and implement `check($container)`.
3. Add a factory function in `lib/Testcontainers/Wait.pm` (e.g., `for_my_strategy()`).
4. Add a test in `t/03-wait-strategies.t`.

### Updating CI/CD

Workflow files live in `.github/workflows/`. The CI has 4 jobs: `lint` (perlcritic), `test-unit` (matrix: 5.40, 5.42), `test-integration` (requires Docker), and `ci-success` (gate).

## Testing Expectations

- Every new public API must have at least one test.
- Tests use `Test::More` and `Test::Exception`.
- Unit tests (t/01-03, t/06-12) run without Docker.
- Integration tests (t/04, t/05) require Docker and `TESTCONTAINERS_LIVE=1`.
- Always clean up containers with `$container->terminate` or `terminate_container()`.

## Additional Best Practices

- Prefer `//` (defined-or) over `||` for defaults.
- Use `eval { ... }; if ($@) { ... }` for error handling, propagate errors with `croak`.
- Keep `$log->debugf(...)` calls for traceability.
- Use `Exporter` with `@EXPORT_OK` — never pollute the caller's namespace by default.
- Keep Docker endpoint configuration via `DOCKER_HOST` env var; do not hardcode endpoints in tests.
- Validate inputs at module boundaries with `croak`.
