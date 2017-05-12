# NAME

Test::RedisServer - redis-server runner for tests.

# SYNOPSIS

    use Redis;
    use Test::RedisServer;
    use Test::More;
    
    my $redis_server;
    eval {
        $redis_server = Test::RedisServer->new;
    } or plan skip_all => 'redis-server is required for this test';
    
    my $redis = Redis->new( $redis_server->connect_info );
    
    is $redis->ping, 'PONG', 'ping pong ok';
    
    done_testing;

# DESCRIPTION

# METHODS

## new(%options)

    my $redis_server = Test::RedisServer->new(%options);

Create a new redis-server instance, and start it by default (use auto\_start option to avoid this)

Available options are:

- auto\_start => 0 | 1 (Default: 1)

    Automatically start redis-server instance (by default).
    You can disable this feature by `auto_start => 0`, and start instance manually by `start` or `exec` method below.

- conf => 'HashRef'

    This is a redis.conf key value pair. You can use any key-value pair(s) that redis-server supports.

    If you want to use this redis.conf:

        port 9999
        databases 16
        save 900 1

    Your conf parameter will be:

        Test::RedisServer->new( conf => {
            port      => 9999,
            databases => 16,
            save      => '900 1',
        });

- timeout => 'Int'

    Timeout seconds for detecting if redis-server is awake or not. (Default: 3)

- tmpdir => 'String'

    Temporal directory, where redis config will be stored. By default it is created for you, but if you start Test::RedisServer via exec (e.g. with Test::TCP), you should provide it to be automatically deleted:

## start

Start redis-server instance manually.

## exec

Just exec to redis-server instance. This method is useful to use this module with [Test::TCP](https://metacpan.org/pod/Test::TCP), [Proclet](https://metacpan.org/pod/Proclet) or etc.

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
            my $redis = Test::RedisServer->new(
                auto_start => 0,
                conf       => { port => $port },
                tmpdir     => $tmp_dir,
            );
            $redis->exec;
        },
    );

## stop

Stop redis-server instance.

This method is automatically called from object destructor, DESTROY.

## connect\_info

Return connection info for client library to connect this redis-server instance.

This parameter is designed to pass directly to [Redis](https://metacpan.org/pod/Redis) module.

    my $redis_server = Test::RedisServer->new;
    my $redis = Redis->new( $redis_server->connect_info );

## pid

Return redis-server instance's process id, or undef when redis-server is not running.

## wait\_exit

Block until redis instance exited. 

# SEE ALSO

[Test::mysqld](https://metacpan.org/pod/Test::mysqld) for mysqld.

[Test::Memcached](https://metacpan.org/pod/Test::Memcached) for Memcached.

This module steals lots of stuff from above modules.

[Test::Mock::Redis](https://metacpan.org/pod/Test::Mock::Redis), another approach for testing redis application.

# INTERNAL METHODS

## BUILD

## DEMOLISH

# AUTHOR

Daisuke Murase <typester@cpan.org>

# COPYRIGHT AND LICENSE

Copyright (c) 2012 KAYAC Inc. All rights reserved.

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.
