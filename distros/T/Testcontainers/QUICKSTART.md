# Quick Start Guide

Get started with Testcontainers for Perl 5 in 5 minutes.

## Prerequisites

- Perl 5.40+
- Docker daemon running (local or remote)

## Installation

```bash
# Install dependencies
cpanm --installdeps .

# Build
perl Build.PL && ./Build

# Verify installation
prove -l t/01-load.t
```

## Basic Usage

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

# Use the container
use HTTP::Tiny;
my $resp = HTTP::Tiny->new->get("http://$host:$port/");
say "Status: $resp->{status}";   # 200

# Clean up
$container->terminate;
```

## Using Pre-Built Modules

### PostgreSQL

```perl
use Testcontainers::Module::PostgreSQL qw( postgres_container );

my $pg = postgres_container(
    username => 'myuser',
    password => 'mypass',
    database => 'mydb',
);

my $dsn  = $pg->dsn;                # "dbi:Pg:dbname=mydb;host=localhost;port=32789"
my $conn = $pg->connection_string;   # "postgresql://myuser:mypass@localhost:32789/mydb"

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

my $dsn = $mysql->dsn;   # "dbi:mysql:database=mydb;host=localhost;port=32790"
$mysql->terminate;
```

### Redis

```perl
use Testcontainers::Module::Redis qw( redis_container );

my $redis = redis_container();
my $url = $redis->connection_string;   # "redis://localhost:32791"
$redis->terminate;
```

### Nginx

```perl
use Testcontainers::Module::Nginx qw( nginx_container );

my $nginx = nginx_container();
my $url = $nginx->base_url;   # "http://localhost:32792"
$nginx->terminate;
```

## Wait Strategies

Wait strategies determine when a container is "ready":

```perl
use Testcontainers::Wait;

# TCP port listening
my $wait = Testcontainers::Wait::for_listening_port('5432/tcp');

# Lowest exposed port
my $wait = Testcontainers::Wait::for_exposed_port();

# HTTP endpoint
my $wait = Testcontainers::Wait::for_http('/health');

# HTTP with options
my $wait = Testcontainers::Wait::for_http('/api/status',
    port        => '8080/tcp',
    status_code => 200,
    method      => 'GET',
);

# Log message (string or regex)
my $wait = Testcontainers::Wait::for_log('ready to accept connections');
my $wait = Testcontainers::Wait::for_log(qr/listening on port \d+/);

# Docker health check
my $wait = Testcontainers::Wait::for_health_check();

# Combine strategies (all must pass)
my $wait = Testcontainers::Wait::for_all(
    Testcontainers::Wait::for_listening_port('5432/tcp'),
    Testcontainers::Wait::for_log('ready to accept connections'),
);
```

## Using in Tests

### Test::More

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
ok($port, "redis mapped to port $port");

# Cleanup
terminate_container($container);

done_testing;
```

### Multiple Containers

```perl
use Testcontainers qw( run );
use Testcontainers::Module::PostgreSQL qw( postgres_container );
use Testcontainers::Module::Redis qw( redis_container );

my $pg    = postgres_container(database => 'testdb');
my $redis = redis_container();

# Run tests against both...

$pg->terminate;
$redis->terminate;
```

## Advanced Options

```perl
my $container = run('myimage:latest',
    exposed_ports   => ['8080/tcp', '9090/tcp'],
    env             => {
        DB_HOST   => 'localhost',
        LOG_LEVEL => 'debug',
    },
    labels          => {
        'app'     => 'mytest',
        'version' => '1.0',
    },
    cmd             => ['--config', '/etc/app.conf'],
    entrypoint      => ['/usr/local/bin/app'],
    tmpfs           => { '/tmp' => 'rw,size=100m' },
    privileged      => 1,
    network_mode    => 'bridge',
    startup_timeout => 120,
    wait_for        => Testcontainers::Wait::for_http('/health'),
);
```

## Container API Reference

```perl
# Connection
$container->host;                      # Host address
$container->mapped_port('80/tcp');     # Mapped host port
$container->endpoint('80/tcp');        # "host:port"
$container->id;                        # Container ID
$container->name;                      # Container name

# Lifecycle
$container->stop;
$container->start;
$container->terminate;                 # Stop + remove
$container->is_running;

# Interaction
$container->exec(['echo', 'hello']);   # Execute command
$container->logs;                      # Get stdout/stderr
$container->logs(tail => 100);         # Last 100 lines
```

## Environment Variables

| Variable | Description | Default |
|---|---|---|
| `DOCKER_HOST` | Docker daemon URL | `unix:///var/run/docker.sock` |
| `TESTCONTAINERS_LIVE` | Enable integration tests | (unset) |

## Troubleshooting

### "Cannot connect to Docker daemon"

Ensure Docker is running:

```bash
docker info
```

Or set a custom Docker host:

```perl
my $container = run('nginx:alpine',
    docker_host   => 'tcp://192.168.1.100:2375',
    exposed_ports => ['80/tcp'],
);
```

### "No mapping found for port"

Ensure the port is in `exposed_ports` and includes the protocol:

```perl
exposed_ports => ['80/tcp'],   # Correct
exposed_ports => ['80'],       # Also works (assumes /tcp)
```

### Timeout waiting for container

Increase the startup timeout:

```perl
my $container = run('myimage:latest',
    startup_timeout => 120,   # 2 minutes
    wait_for => ...,
);
```

## Next Steps

- Read the [ARCHITECTURE.md](ARCHITECTURE.md) for design details
- See the [README.md](README.md) for the full API reference
- Check [CONTRIBUTING.md](CONTRIBUTING.md) to contribute
