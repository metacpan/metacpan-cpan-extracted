use strict;
use warnings;
use Test::More;
use lib 't/lib';
use Test::WWW::Docker::Mock;

# Tests for WWW::Docker::API::Containers.
# Read / validation subtests run in mock mode without Docker.
# Write subtests require TESTCONTAINERS_LIVE=1 and WWW_DOCKER_TEST_WRITE=1.

check_live_access();

# ---------------------------------------------------------------------------
# Read tests (always run via mock)
# ---------------------------------------------------------------------------

subtest 'list containers' => sub {
    my $docker = test_docker(
        'GET /containers/json' => load_fixture('containers_list'),
    );

    my $containers = $docker->containers->list(all => 1);

    is(ref $containers, 'ARRAY', 'returns array');
    if (@$containers) {
        isa_ok($containers->[0], 'WWW::Docker::Container');
        ok($containers->[0]->Id, 'has Id');
    }

    unless (is_live()) {
        is(scalar @$containers, 2, 'two containers in fixture');

        my $first = $containers->[0];
        is($first->Id,                      'abc123def456',   'container id');
        is_deeply($first->Names,            ['/my-container'], 'container names');
        is($first->Image,                   'nginx:latest',   'container image');
        is($first->State,                   'running',        'container state');
        ok($first->is_running,              'is_running true for running container');

        my $second = $containers->[1];
        is($second->Id,    'def789ghi012', 'second container id');
        is($second->State, 'exited',       'second container state');
        ok(!$second->is_running, 'is_running false for exited container');
    }
};

# ---------------------------------------------------------------------------
# Write tests (mock always safe; live requires WWW_DOCKER_TEST_WRITE=1)
# ---------------------------------------------------------------------------

subtest 'container lifecycle' => sub {
    skip_unless_write();

    my $docker = test_docker(
        'POST /containers/create'          => { Id => 'mock123', Warnings => [] },
        'POST /containers/mock123/start'   => undef,
        'GET /containers/mock123/json'     => load_fixture('container_inspect'),
        'GET /containers/mock123/top'      => {
            Titles    => ['UID', 'PID', 'PPID', 'C', 'STIME', 'TTY', 'TIME', 'CMD'],
            Processes => [['root', '12345', '1', '0', '08:00', '?', '00:00:00', 'sleep']],
        },
        'GET /containers/mock123/stats'    => {
            cpu_stats    => { cpu_usage => { total_usage => 1000 } },
            memory_stats => { usage => 50_000_000 },
        },
        'POST /containers/mock123/pause'   => undef,
        'POST /containers/mock123/unpause' => undef,
        'POST /containers/mock123/stop'    => undef,
        'DELETE /containers/mock123'       => undef,
    );

    my $name    = 'www-docker-test-' . $$;
    my $created = $docker->containers->create(
        name  => $name,
        Image => 'alpine:latest',
        Cmd   => ['sleep', '10'],
    );
    ok($created->{Id}, 'created container has Id');
    my $id = is_live() ? $created->{Id} : 'mock123';

    register_cleanup(sub { eval { $docker->containers->remove($id, force => 1) } }) if is_live();

    $docker->containers->start($id);
    pass('container started');

    my $container = $docker->containers->inspect($id);
    isa_ok($container, 'WWW::Docker::Container');
    ok($container->is_running, 'container is running after start');

    my $top = $docker->containers->top($id);
    is(ref $top->{Processes}, 'ARRAY', 'top returns Processes array');

    my $stats = $docker->containers->stats($id);
    ok($stats->{cpu_stats},    'stats has cpu_stats');
    ok($stats->{memory_stats}, 'stats has memory_stats');

    $docker->containers->pause($id);
    pass('container paused');
    $docker->containers->unpause($id);
    pass('container unpaused');

    $docker->containers->stop($id, timeout => 3);
    pass('container stopped');

    $docker->containers->remove($id);
    pass('container removed');
};

# ---------------------------------------------------------------------------
# Validation tests (always run, no Docker needed)
# ---------------------------------------------------------------------------

subtest 'container ID required' => sub {
    my $docker = test_docker();

    eval { $docker->containers->inspect(undef) };
    like($@, qr/Container ID required/, 'croak on missing ID for inspect');

    eval { $docker->containers->start(undef) };
    like($@, qr/Container ID required/, 'croak on missing ID for start');

    eval { $docker->containers->stop(undef) };
    like($@, qr/Container ID required/, 'croak on missing ID for stop');
};

done_testing;
