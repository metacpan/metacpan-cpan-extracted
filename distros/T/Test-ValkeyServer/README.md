[![Actions Status](https://github.com/plainbanana/Test-ValkeyServer/actions/workflows/test.yaml/badge.svg?branch=master)](https://github.com/plainbanana/Test-ValkeyServer/actions?workflow=test)
# NAME

Test::ValkeyServer - valkey-server runner for tests.

# SYNOPSIS

```perl
use Redis;
use Test::ValkeyServer;
use Test::More;

my $valkey_server;
eval {
    $valkey_server = Test::ValkeyServer->new;
} or plan skip_all => 'valkey-server is required for this test';

my $redis = Redis->new( $valkey_server->connect_info );

is $redis->ping, 'PONG', 'ping pong ok';

done_testing;
```

# DESCRIPTION

Test::ValkeyServer is a fork of [Test::RedisServer](https://metacpan.org/pod/Test%3A%3ARedisServer) adapted for
[Valkey](https://valkey.io/), the open source high-performance key/value store.
It automatically spawns a temporary valkey-server instance for use in your test
suite and cleans it up when done.

This module was forked from [Test::RedisServer](https://metacpan.org/pod/Test%3A%3ARedisServer) version 0.24 by Daisuke Murase
and adapted for Valkey compatibility.

# METHODS

## new(%options)

```perl
my $valkey_server = Test::ValkeyServer->new(%options);
```

Create a new valkey-server instance, and start it by default (use auto\_start option to avoid this)

Available options are:

- auto\_start => 0 | 1 (Default: 1)

    Automatically start valkey-server instance (by default).
    You can disable this feature by `auto_start => 0`, and start instance manually by `start` or `exec` method below.

- conf => 'HashRef'

    This is a valkey.conf key value pair. You can use any key-value pair(s) that valkey-server supports.

    If you want to use this valkey.conf:

    ```
    port 9999
    databases 16
    save 900 1
    ```

    Your conf parameter will be:

    ```perl
    Test::ValkeyServer->new( conf => {
        port      => 9999,
        databases => 16,
        save      => '900 1',
    });
    ```

- cluster => 0 | 1 (Default: 0)

    Enable single-node cluster mode. Unix sockets are not supported in this mode
    (specifying `unixsocket` in `conf` throws an error), and
    `valkey-cli --cluster create` is called after the server starts. A TCP port
    must be specified via `conf`. Requires `valkey-cli` in PATH and Valkey 8.1+.

    ```perl
    use Test::TCP qw(empty_port);
    my $server = Test::ValkeyServer->new(
        cluster => 1,
        conf    => { port => empty_port(), bind => '127.0.0.1' },
    );
    my $redis = Redis->new($server->connect_info);
    # Now you can use cluster commands
    ```

    Note: cluster mode is not compatible with `exec()`; use `start()` instead.

- timeout => 'Int'

    Timeout seconds for detecting if valkey-server is awake or not. (Default: 3)
    In cluster mode, this timeout applies to both server startup and cluster creation separately.

- tmpdir => 'String'

    Temporal directory, where valkey config will be stored. By default it is created for you, but if you start Test::ValkeyServer via exec (e.g. with Test::TCP), you should provide it to be automatically deleted:

## start

Start valkey-server instance manually.

## exec

Just exec to valkey-server instance. This method is useful to use this module with [Test::TCP](https://metacpan.org/pod/Test%3A%3ATCP), [Proclet](https://metacpan.org/pod/Proclet) or etc.

```perl
use File::Temp;
use Test::TCP;
my $tmp_dir = File::Temp->newdir( CLEANUP => 1 );

test_tcp(
    client => sub {
        my ($port, $server_pid) = @_;
        ...
    },
    server => sub {
        my ($port) = @_;
        my $valkey = Test::ValkeyServer->new(
            auto_start => 0,
            conf       => { port => $port },
            tmpdir     => $tmp_dir,
        );
        $valkey->exec;
    },
);
```

## stop

Stop valkey-server instance.

This method is automatically called from object destructor, DEMOLISH.

## connect\_info

Return connection info for client library to connect this valkey-server instance.

This parameter is designed to pass directly to [Redis](https://metacpan.org/pod/Redis) module.

```perl
my $valkey_server = Test::ValkeyServer->new;
my $redis = Redis->new( $valkey_server->connect_info );
```

## pid

Return valkey-server instance's process id, or undef when valkey-server is not running.

## wait\_exit

Block until valkey instance exited.

# SEE ALSO

[Test::mysqld](https://metacpan.org/pod/Test%3A%3Amysqld) for mysqld.

[Test::Memcached](https://metacpan.org/pod/Test%3A%3AMemcached) for Memcached.

This module steals lots of stuff from above modules.

[Test::RedisServer](https://metacpan.org/pod/Test%3A%3ARedisServer), the original module this was forked from.

# INTERNAL METHODS

## BUILD

## DEMOLISH

# AUTHOR

Daisuke Murase <typester@cpan.org> (original [Test::RedisServer](https://metacpan.org/pod/Test%3A%3ARedisServer) author)

Current maintainer: plainbanana

# COPYRIGHT AND LICENSE

Copyright (c) 2012 KAYAC Inc. All rights reserved.

Forked as Test::ValkeyServer in 2025 by plainbanana.

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.
