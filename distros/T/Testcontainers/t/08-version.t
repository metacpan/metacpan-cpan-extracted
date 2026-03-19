use strict;
use warnings;
use Test::More;
use lib 't/lib';
use Test::WWW::Docker::Mock;

# Tests for WWW::Docker version information and API version negotiation.
# Runs in mock mode without Docker.  Set TESTCONTAINERS_LIVE=1 to run against
# a real daemon.

check_live_access();

# ---------------------------------------------------------------------------

subtest 'version info' => sub {
    my $docker = test_docker(
        'GET /version' => load_fixture('system_version'),
    );

    my $version = $docker->system->version;

    ok($version->{ApiVersion}, 'has ApiVersion');
    ok($version->{Version},    'has Version');
    ok($version->{Os},         'has Os');
    ok($version->{Arch},       'has Arch');

    unless (is_live()) {
        is($version->{ApiVersion},    '1.47',       'ApiVersion');
        is($version->{Version},       '27.4.1',     'Version');
        is($version->{Os},            'linux',      'Os');
        is($version->{Arch},          'amd64',      'Arch');
        is($version->{GoVersion},     'go1.22.10',  'GoVersion');
        is($version->{MinAPIVersion}, '1.24',       'MinAPIVersion');
    }
};

# ---------------------------------------------------------------------------

subtest 'explicit api_version bypasses negotiation' => sub {
    my $docker = WWW::Docker->new(api_version => '1.45');
    is($docker->api_version, '1.45', 'explicit version is preserved as-is');
};

# ---------------------------------------------------------------------------

subtest 'auto-negotiate api_version' => sub {
    if (is_live()) {
        my $host   = $ENV{WWW_DOCKER_TEST_HOST} || 'unix:///var/run/docker.sock';
        my $docker = WWW::Docker->new(host => $host);
        $docker->negotiate_version;
        ok(defined $docker->api_version, 'api_version was negotiated');
        like($docker->api_version, qr/^\d+\.\d+$/, 'version looks like N.N');
    }
    else {
        my $docker = test_docker(
            'GET /version' => load_fixture('system_version'),
        );
        is($docker->api_version, '1.47', 'mock api_version matches fixture');
    }
};

done_testing;
