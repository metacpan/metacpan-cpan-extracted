use strict;
use warnings;
use Test::More;

# Integration tests that require Docker
# Set TESTCONTAINERS_LIVE=1 to run these tests

unless ($ENV{TESTCONTAINERS_LIVE}) {
    plan skip_all => 'Set TESTCONTAINERS_LIVE=1 to run integration tests (requires Docker)';
}

use Testcontainers qw( run terminate_container );
use Testcontainers::Wait;

subtest 'run nginx container' => sub {
    my $container = run('nginx:alpine',
        exposed_ports => ['80/tcp'],
        wait_for      => Testcontainers::Wait::for_http('/',
            port        => '80/tcp',
            status_code => 200,
        ),
    );

    ok($container, 'container created');
    ok($container->id, 'has container ID');
    like($container->id, qr/^[a-f0-9]+$/, 'valid container ID format');

    my $host = $container->host;
    is($host, 'localhost', 'host is localhost');

    my $port = $container->mapped_port('80/tcp');
    ok($port, 'port is mapped');
    like($port, qr/^\d+$/, 'port is numeric');

    my $endpoint = $container->endpoint('80/tcp');
    like($endpoint, qr/^localhost:\d+$/, 'endpoint format');

    ok($container->is_running, 'container is running');

    terminate_container($container);
    ok(!eval { $container->is_running }, 'container terminated');
};

subtest 'run with environment variables' => sub {
    my $container = run('nginx:alpine',
        exposed_ports => ['80/tcp'],
        env           => { NGINX_HOST => 'testhost', MY_VAR => 'hello' },
        wait_for      => Testcontainers::Wait::for_listening_port('80/tcp'),
    );

    ok($container, 'container with env created');
    ok($container->is_running, 'running');

    terminate_container($container);
};

subtest 'run with labels' => sub {
    my $container = run('nginx:alpine',
        exposed_ports => ['80/tcp'],
        labels        => { 'test.label' => 'my-test' },
        wait_for      => Testcontainers::Wait::for_listening_port('80/tcp'),
    );

    ok($container, 'container with labels created');

    terminate_container($container);
};

subtest 'exec in container' => sub {
    my $container = run('nginx:alpine',
        exposed_ports => ['80/tcp'],
        wait_for      => Testcontainers::Wait::for_listening_port('80/tcp'),
    );

    my $result = $container->exec(['echo', 'hello', 'world']);
    ok(defined $result, 'exec returned result');

    terminate_container($container);
};

subtest 'container logs' => sub {
    my $container = run('nginx:alpine',
        exposed_ports => ['80/tcp'],
        wait_for      => Testcontainers::Wait::for_listening_port('80/tcp'),
    );

    my $logs = $container->logs;
    ok(defined $logs, 'got logs');

    terminate_container($container);
};

subtest 'HTTP wait strategy' => sub {
    my $container = run('nginx:alpine',
        exposed_ports => ['80/tcp'],
        wait_for      => Testcontainers::Wait::for_http('/'),
    );

    ok($container, 'container ready via HTTP wait');
    ok($container->is_running, 'running');

    terminate_container($container);
};

subtest 'log wait strategy' => sub {
    my $container = run('nginx:alpine',
        exposed_ports => ['80/tcp'],
        wait_for      => Testcontainers::Wait::for_log('start worker process'),
    );

    ok($container, 'container ready via log wait');

    terminate_container($container);
};

subtest 'multi wait strategy' => sub {
    my $container = run('nginx:alpine',
        exposed_ports => ['80/tcp'],
        wait_for      => Testcontainers::Wait::for_all(
            Testcontainers::Wait::for_listening_port('80/tcp'),
            Testcontainers::Wait::for_log('start worker process'),
        ),
    );

    ok($container, 'container ready via multi wait');

    terminate_container($container);
};

done_testing;
