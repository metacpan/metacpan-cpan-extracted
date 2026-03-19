[![CI/CD](https://github.com/dragosv/testcontainers-perl5/actions/workflows/ci.yml/badge.svg?branch=main)](https://github.com/dragosv/testcontainers-perl5/actions/workflows/ci.yml)
[![Language](https://img.shields.io/badge/Perl-5.40+-blue.svg)](https://www.perl.org/)
[![Docker](https://img.shields.io/badge/Docker%20Engine%20API-%20%201.44-blue)](https://docs.docker.com/engine/api/v1.44/)
[![PRs Welcome](https://img.shields.io/badge/PRs-welcome-brightgreen.svg?style=shields)](http://makeapullrequest.com)

# Testcontainers for Perl 5

Perl 5 implementation of [Testcontainers](https://testcontainers.com/), inspired by the
[Go reference implementation](https://golang.testcontainers.org/). 

Testcontainers makes it simple to create and clean up container-based
dependencies for automated integration/smoke tests.

## Requirements

- Perl 5.40+
- Docker daemon (local or remote)

## Installation

```bash
cpanm --installdeps .
perl Build.PL && ./Build && ./Build install
```

## Quick Start

```perl
use Testcontainers qw( run );
use Testcontainers::Wait;

# Run an nginx container
my $container = run('nginx:alpine',
    exposed_ports => ['80/tcp'],
    wait_for      => Testcontainers::Wait::for_listening_port('80/tcp'),
);

# Get connection details
my $host = $container->host;        # "localhost"
my $port = $container->mapped_port('80/tcp');  # e.g., "32789"

# Use the container...
use HTTP::Tiny;
my $response = HTTP::Tiny->new->get("http://$host:$port/");
say $response->{status};  # 200

# Clean up when done
$container->terminate;
```

## Container Modules

Pre-built modules provide sensible defaults for popular services:

### PostgreSQL

```perl
use Testcontainers::Module::PostgreSQL qw( postgres_container );

my $pg = postgres_container(
    username => 'myuser',
    password => 'mypass',
    database => 'mydb',
);

my $dsn  = $pg->dsn;               # "dbi:Pg:dbname=mydb;host=localhost;port=32789"
my $conn = $pg->connection_string;  # "postgresql://myuser:mypass@localhost:32789/mydb"

# Use with DBI
use DBI;
my $dbh = DBI->connect($dsn, 'myuser', 'mypass');

$pg->terminate;
```

### MySQL

```perl
use Testcontainers::Module::MySQL qw( mysql_container );

my $mysql = mysql_container(
    username => 'myuser',
    password => 'mypass',
    database => 'mydb',
);

my $dsn = $mysql->dsn;  # "dbi:mysql:database=mydb;host=localhost;port=32790"
$mysql->terminate;
```

### Redis

```perl
use Testcontainers::Module::Redis qw( redis_container );

my $redis = redis_container();
my $url = $redis->connection_string;  # "redis://localhost:32791"
$redis->terminate;
```

### Nginx

```perl
use Testcontainers::Module::Nginx qw( nginx_container );

my $nginx = nginx_container();
my $url = $nginx->base_url;  # "http://localhost:32792"
$nginx->terminate;
```

## Wait Strategies

Wait strategies determine when a container is "ready" for use:

```perl
use Testcontainers::Wait;

# Wait for a TCP port to be listening
Testcontainers::Wait::for_listening_port('5432/tcp');

# Wait for the lowest exposed port
Testcontainers::Wait::for_exposed_port();

# Wait for an HTTP endpoint
Testcontainers::Wait::for_http('/health');
Testcontainers::Wait::for_http('/api/status',
    port        => '8080/tcp',
    status_code => 200,
    method      => 'GET',
);

# Wait for a log message (string or regex)
Testcontainers::Wait::for_log('ready to accept connections');
Testcontainers::Wait::for_log(qr/listening on port \d+/);

# Wait for Docker health check
Testcontainers::Wait::for_health_check();

# Combine multiple strategies
Testcontainers::Wait::for_all(
    Testcontainers::Wait::for_listening_port('5432/tcp'),
    Testcontainers::Wait::for_log('ready to accept connections'),
);
```

## Container API

```perl
my $container = Testcontainers::run('myimage:latest', ...);

# Connection
$container->host;                    # Host address
$container->mapped_port('80/tcp');   # Mapped host port
$container->endpoint('80/tcp');      # "host:port"
$container->id;                      # Container ID
$container->name;                    # Container name

# Lifecycle
$container->stop;
$container->start;
$container->terminate;               # Stop + remove
$container->is_running;

# Interaction
$container->exec(['echo', 'hello']); # Execute command
$container->logs;                    # Get stdout/stderr
$container->logs(tail => 100);       # Last 100 lines
```

## Advanced Usage

### Custom Container Configuration

```perl
my $container = run('myimage:latest',
    exposed_ports   => ['8080/tcp', '9090/tcp'],
    env             => {
        DB_HOST     => 'localhost',
        DB_PORT     => '5432',
        LOG_LEVEL   => 'debug',
    },
    labels          => {
        'app'       => 'mytest',
        'version'   => '1.0',
    },
    cmd             => ['--config', '/etc/myapp.conf'],
    entrypoint      => ['/usr/local/bin/myapp'],
    tmpfs           => { '/tmp' => 'rw,size=100m' },
    privileged      => 1,
    network_mode    => 'bridge',
    startup_timeout => 120,
    wait_for        => Testcontainers::Wait::for_http('/health'),
);
```

### Using in Test::More

```perl
use Test::More;
use Testcontainers qw( run terminate_container );
use Testcontainers::Wait;

my $container;

# Setup
$container = run('redis:7-alpine',
    exposed_ports => ['6379/tcp'],
    wait_for      => Testcontainers::Wait::for_listening_port('6379/tcp'),
);

# Tests
ok($container->is_running, 'redis is running');
my $port = $container->mapped_port('6379/tcp');
ok($port, "redis port: $port");

# Cleanup
terminate_container($container);

done_testing;
```

## Architecture

```
Testcontainers                       # Main entry point, run() function
├── Container                        # Running container instance
├── ContainerRequest                 # Container configuration builder
├── DockerClient                     # WWW::Docker wrapper
├── Wait                             # Wait strategy factory
│   ├── Base                         # Base role for strategies
│   ├── HostPort                     # TCP port listening
│   ├── HTTP                         # HTTP endpoint check
│   ├── Log                          # Log message matching
│   ├── HealthCheck                  # Docker health check
│   └── Multi                        # Composite (all must pass)
└── Module                           # Pre-built container modules
    ├── PostgreSQL
    ├── MySQL
    ├── Redis
    └── Nginx
```

## Running Tests

```bash
# Unit tests (no Docker required)
prove -l t/01-load.t t/02-container-request.t t/03-wait-strategies.t

# Integration tests (requires Docker)
TESTCONTAINERS_LIVE=1 prove -l t/04-integration.t t/05-modules.t
```

## Environment Variables

| Variable | Description | Default |
|---|---|---|
| `DOCKER_HOST` | Docker daemon URL | `unix:///var/run/docker.sock` |
| `TESTCONTAINERS_LIVE` | Enable integration tests | (unset) |

## Comparison with Go Testcontainers

| Go | Perl |
|---|---|
| `testcontainers.Run(ctx, image, opts...)` | `Testcontainers::run($image, %opts)` |
| `container.Host(ctx)` | `$container->host` |
| `container.MappedPort(ctx, "80/tcp")` | `$container->mapped_port('80/tcp')` |
| `testcontainers.TerminateContainer(c)` | `$container->terminate` |
| `wait.ForListeningPort("80/tcp")` | `Testcontainers::Wait::for_listening_port('80/tcp')` |
| `wait.ForHTTP("/")` | `Testcontainers::Wait::for_http('/')` |
| `wait.ForLog("ready")` | `Testcontainers::Wait::for_log('ready')` |
| `testcontainers.WithEnv(map)` | `env => { ... }` |
| `testcontainers.WithExposedPorts(...)` | `exposed_ports => [...]` |

## License

This software is copyright (c) 2026 by Testcontainers Contributors.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

## Acknowledgments

This project includes code derived from [WWW::Docker](https://github.com/Getty/p5-www-docker) by [Torsten Raudssus](https://github.com/getty), licensed under Perl license.