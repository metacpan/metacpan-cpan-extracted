use strict;
use warnings;
use Test::More;
use Test::Exception;

use Testcontainers::ContainerRequest;
use Testcontainers::Labels qw(
    LABEL_BASE LABEL_LANG LABEL_VERSION LABEL_SESSION_ID LABEL_REAP
    session_id
);

# Test container request creation
subtest 'basic request' => sub {
    my $req = Testcontainers::ContainerRequest->new(
        image         => 'nginx:alpine',
        exposed_ports => ['80/tcp'],
    );
    is($req->image, 'nginx:alpine', 'image set');
    is_deeply($req->exposed_ports, ['80/tcp'], 'exposed_ports set');
    is($req->startup_timeout, 60, 'default startup_timeout');
    is_deeply($req->env, {}, 'default empty env');
    is_deeply($req->cmd, [], 'default empty cmd');
};

subtest 'request with all options' => sub {
    my $req = Testcontainers::ContainerRequest->new(
        image           => 'postgres:16-alpine',
        exposed_ports   => ['5432/tcp'],
        env             => { POSTGRES_PASSWORD => 'test' },
        labels          => { app => 'mytest' },
        cmd             => ['-c', 'max_connections=100'],
        name            => 'test-pg',
        startup_timeout => 120,
        privileged      => 1,
        tmpfs           => { '/tmp' => 'rw' },
        network_mode    => 'bridge',
    );

    is($req->image, 'postgres:16-alpine', 'image');
    is_deeply($req->env, { POSTGRES_PASSWORD => 'test' }, 'env');
    is_deeply($req->labels, { app => 'mytest' }, 'labels');
    is($req->name, 'test-pg', 'name');
    is($req->startup_timeout, 120, 'startup_timeout');
    is($req->privileged, 1, 'privileged');
};

subtest 'to_docker_config' => sub {
    my $req = Testcontainers::ContainerRequest->new(
        image         => 'nginx:alpine',
        exposed_ports => ['80/tcp', '443/tcp'],
        env           => { FOO => 'bar', BAZ => 'qux' },
        labels        => { custom => 'label' },
        cmd           => ['nginx', '-g', 'daemon off;'],
    );

    my $config = $req->to_docker_config;

    is($config->{Image}, 'nginx:alpine', 'docker config image');
    ok(exists $config->{ExposedPorts}{'80/tcp'}, 'port 80 exposed');
    ok(exists $config->{ExposedPorts}{'443/tcp'}, 'port 443 exposed');

    # Env should be sorted key=value format
    is_deeply($config->{Env}, ['BAZ=qux', 'FOO=bar'], 'env in sorted key=value format');

    # Labels should include testcontainers labels
    is($config->{Labels}{custom}, 'label', 'custom label preserved');
    is($config->{Labels}{ LABEL_BASE() },       'true',  'base label');
    is($config->{Labels}{ LABEL_LANG() },       'perl',  'lang label');
    is($config->{Labels}{ LABEL_VERSION() },    '0.001', 'version label');
    ok($config->{Labels}{ LABEL_SESSION_ID() },          'session id label present');
    like($config->{Labels}{ LABEL_SESSION_ID() },
        qr/^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/,
        'session id is a valid UUID v4');
    is($config->{Labels}{ LABEL_REAP() }, 'true', 'reap label present (Ryuk enabled by default)');

    is_deeply($config->{Cmd}, ['nginx', '-g', 'daemon off;'], 'cmd');

    # HostConfig port bindings
    ok(exists $config->{HostConfig}{PortBindings}{'80/tcp'}, 'port binding 80');
    ok(exists $config->{HostConfig}{PortBindings}{'443/tcp'}, 'port binding 443');
};

subtest 'port normalization' => sub {
    my $req = Testcontainers::ContainerRequest->new(
        image         => 'nginx:alpine',
        exposed_ports => ['80'],  # without protocol
    );

    my $config = $req->to_docker_config;
    ok(exists $config->{ExposedPorts}{'80/tcp'}, 'bare port normalized to /tcp');
};

subtest 'tmpfs config' => sub {
    my $req = Testcontainers::ContainerRequest->new(
        image => 'nginx:alpine',
        tmpfs => { '/tmp' => 'rw', '/run' => 'rw,size=100m' },
    );

    my $config = $req->to_docker_config;
    is_deeply($config->{HostConfig}{Tmpfs}, { '/tmp' => 'rw', '/run' => 'rw,size=100m' }, 'tmpfs');
};

subtest 'reserved label prefix is rejected' => sub {
    throws_ok {
        my $req = Testcontainers::ContainerRequest->new(
            image  => 'nginx:alpine',
            labels => { 'org.testcontainers.custom' => 'nope' },
        );
        $req->to_docker_config;
    } qr/reserved.*org\.testcontainers/, 'org.testcontainers.* prefix rejected';
};

subtest 'reap label omitted when Ryuk disabled' => sub {
    local $ENV{TESTCONTAINERS_RYUK_DISABLED} = '1';
    my $req = Testcontainers::ContainerRequest->new(
        image => 'nginx:alpine',
    );
    my $config = $req->to_docker_config;
    ok(!exists $config->{Labels}{ LABEL_REAP() }, 'reap label absent when Ryuk disabled');
    is($config->{Labels}{ LABEL_BASE() }, 'true', 'base label still present');
};

subtest 'session_id is stable across calls' => sub {
    my $sid1 = session_id();
    my $sid2 = session_id();
    is($sid1, $sid2, 'session_id returns same value within a process');
    like($sid1, qr/^[0-9a-f]{8}-/, 'looks like a UUID');
};

done_testing;
