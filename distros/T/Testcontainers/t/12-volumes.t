use strict;
use warnings;
use Test::More;
use lib 't/lib';
use Test::WWW::Docker::Mock;

# Tests for WWW::Docker::API::Volumes.
# Read / validation subtests run in mock mode without Docker.
# Write subtests require TESTCONTAINERS_LIVE=1 and WWW_DOCKER_TEST_WRITE=1.

check_live_access();

# ---------------------------------------------------------------------------
# Read tests (always run via mock)
# ---------------------------------------------------------------------------

subtest 'list volumes' => sub {
    my $docker = test_docker(
        'GET /volumes' => load_fixture('volumes_list'),
    );

    my $volumes = $docker->volumes->list;

    is(ref $volumes, 'ARRAY', 'returns array');
    if (@$volumes) {
        isa_ok($volumes->[0], 'WWW::Docker::Volume');
        ok($volumes->[0]->Name, 'has Name');
    }

    unless (is_live()) {
        is(scalar @$volumes, 2, 'two volumes in fixture');

        my $first = $volumes->[0];
        is($first->Name,   'my-data', 'volume name');
        is($first->Driver, 'local',   'volume driver');
        is($first->Scope,  'local',   'volume scope');
        is_deeply($first->Labels, { project => 'test' }, 'volume labels');
        like($first->Mountpoint, qr{/var/lib/docker/volumes/my-data}, 'mountpoint path');
    }
};

# ---------------------------------------------------------------------------
# Write tests (mock always safe; live requires WWW_DOCKER_TEST_WRITE=1)
# ---------------------------------------------------------------------------

subtest 'volume lifecycle' => sub {
    skip_unless_write();

    my $docker = test_docker(
        'POST /volumes/create' => sub {
            my ($method, $path, %opts) = @_;
            is($opts{body}{Name}, 'test-vol', 'volume name in body') unless is_live();
            return {
                Name       => 'test-vol',
                Driver     => 'local',
                Mountpoint => '/var/lib/docker/volumes/test-vol/_data',
                CreatedAt  => '2025-01-15T12:00:00Z',
                Labels     => {},
                Scope      => 'local',
                Options    => {},
            };
        },
        'GET /volumes/test-vol'    => {
            Name       => 'test-vol',
            Driver     => 'local',
            Mountpoint => '/var/lib/docker/volumes/test-vol/_data',
            CreatedAt  => '2025-01-10T08:00:00Z',
            Labels     => {},
            Scope      => 'local',
            Options    => {},
        },
        'DELETE /volumes/test-vol' => undef,
    );

    my $name   = is_live() ? 'www-docker-test-vol-' . $$ : 'test-vol';
    my $volume = $docker->volumes->create(Name => $name);
    isa_ok($volume, 'WWW::Docker::Volume');
    ok($volume->Name, 'created volume has Name');

    register_cleanup(sub { eval { $docker->volumes->remove($name, force => 1) } }) if is_live();

    my $inspected = $docker->volumes->inspect($name);
    isa_ok($inspected, 'WWW::Docker::Volume');
    is($inspected->Driver, 'local', 'inspected volume driver is local');

    $docker->volumes->remove($name);
    pass('volume removed');
};

# ---------------------------------------------------------------------------
# Validation tests (always run, no Docker needed)
# ---------------------------------------------------------------------------

subtest 'volume name required' => sub {
    my $docker = test_docker();

    eval { $docker->volumes->inspect(undef) };
    like($@, qr/Volume name required/, 'croak on missing name for inspect');

    eval { $docker->volumes->remove(undef) };
    like($@, qr/Volume name required/, 'croak on missing name for remove');
};

done_testing;
