# Contributing to Testcontainers Perl 5

First off, thank you for considering contributing to Testcontainers for Perl 5! It's people like you that make Testcontainers such a great tool.

## Code of Conduct

This project adheres to the [Contributor Covenant Code of Conduct](CODE_OF_CONDUCT.md). By participating, you are expected to uphold this code.

## How to Contribute

### Reporting Bugs

- Check the [issue tracker](https://github.com/dragosv/testcontainers-perl5/issues) for duplicates.
- Include your Perl version (`perl -v`), OS, and Docker version (`docker version`).
- Provide a minimal reproduction if possible.

### Suggesting Features

- Open a [feature request](https://github.com/dragosv/testcontainers-perl5/issues/new) and describe the use case.

### Pull Requests

1. Fork the repository.
2. Create a feature branch from `main`:

   ```bash
   git checkout -b feature/my-feature
   ```

3. Install dependencies:

   ```bash
   cpanm --installdeps .
   ```

4. Build:

   ```bash
   perl Build.PL && ./Build
   ```

5. Run unit tests (no Docker required):

   ```bash
   prove -l t/01-load.t t/02-container-request.t t/03-wait-strategies.t
   ```

6. Run all tests (requires Docker):

   ```bash
   TESTCONTAINERS_LIVE=1 prove -l t/
   ```

7. Commit, push, and open a PR against `main`.

## Perl Code Style

- `use strict; use warnings;` in every file.
- 4-space indentation.
- `snake_case` for subroutines, variables, and file names.
- `PascalCase` for package names.
- ~120-character line limit.
- All public APIs must have POD documentation.
- Use `Carp::croak` for user-facing errors.
- Use `Log::Any` for debug output.

### Example

```perl
package Testcontainers::Wait::MyStrategy;
use Moo;
with 'Testcontainers::Wait::Base';

use Carp qw( croak );
use Log::Any qw( $log );

has some_option => (
    is      => 'ro',
    default => 'value',
);

sub check {
    my ($self, $container) = @_;
    $log->debugf("Checking with option: %s", $self->some_option);
    # Return 1 if ready, 0 if not
    return 1;
}

1;
```

## Adding a Container Module

1. Create `lib/Testcontainers/Module/MyService.pm`:

```perl
package Testcontainers::Module::MyService;
use strict;
use warnings;
use Exporter 'import';
our @EXPORT_OK = qw( myservice_container );

use Testcontainers qw( run );
use Testcontainers::Wait;

my $DEFAULT_IMAGE = 'myservice:latest';
my $DEFAULT_PORT  = '1234/tcp';

sub myservice_container {
    my (%opts) = @_;
    my $image = $opts{image} // $DEFAULT_IMAGE;

    my $container = run($image,
        exposed_ports    => [$DEFAULT_PORT],
        env              => { MY_VAR => $opts{my_var} // 'default' },
        _internal_labels => { 'org.testcontainers.module' => 'myservice' },
        wait_for         => Testcontainers::Wait::for_listening_port($DEFAULT_PORT),
        startup_timeout  => $opts{startup_timeout} // 60,
    );

    return Testcontainers::Module::MyService::Container->new(
        _container => $container,
    );
}

# Inner container class with convenience methods
package Testcontainers::Module::MyService::Container;
use Moo;

has _container => (is => 'ro', required => 1, handles => [qw(
    id host mapped_port endpoint exec logs stop start terminate
    is_running container_id
)]);

sub connection_string {
    my ($self) = @_;
    my $host = $self->host;
    my $port = $self->mapped_port($DEFAULT_PORT);
    return "myservice://$host:$port";
}

1;
```

2. Add tests in `t/05-modules.t` or a new test file.
3. Update `README.md` with a usage example.

## Commit Messages

Follow [Conventional Commits](https://www.conventionalcommits.org/):

```
feat: add MyService module
fix: correct port mapping for UDP
docs: update QUICKSTART with MyService example
test: add integration test for MyService module
chore: update cpanfile dependencies
```

## Testing

- Unit tests (`t/01-03`, `t/06-12`) must not require Docker.
- Integration tests (`t/04`, `t/05`) must guard with `$ENV{TESTCONTAINERS_LIVE}`.
- Always clean up containers (`$container->terminate`).
- Use `Test::More` and `Test::Exception`.

## Questions?

Open an issue or start a discussion. We're happy to help!
