use strict;
use warnings;
use Test::More;

use Testcontainers::Wait;
use Testcontainers::Wait::HostPort;
use Testcontainers::Wait::HTTP;
use Testcontainers::Wait::Log;
use Testcontainers::Wait::HealthCheck;
use Testcontainers::Wait::Multi;

# Unit tests for wait strategy creation (no Docker required)

subtest 'for_listening_port' => sub {
    my $wait = Testcontainers::Wait::for_listening_port('80/tcp');
    isa_ok($wait, 'Testcontainers::Wait::HostPort');
    is($wait->port, '80/tcp', 'port set');
    is($wait->startup_timeout, 60, 'default timeout');
    is($wait->poll_interval, 0.1, 'default poll interval');
};

subtest 'for_exposed_port' => sub {
    my $wait = Testcontainers::Wait::for_exposed_port();
    isa_ok($wait, 'Testcontainers::Wait::HostPort');
    ok($wait->use_lowest_port, 'use_lowest_port flag');
};

subtest 'for_http' => sub {
    my $wait = Testcontainers::Wait::for_http('/health');
    isa_ok($wait, 'Testcontainers::Wait::HTTP');
    is($wait->path, '/health', 'path set');
    is($wait->status_code, 200, 'default status code');
    is($wait->method, 'GET', 'default method');
    ok(!$wait->tls, 'TLS off by default');
};

subtest 'for_http with options' => sub {
    my $wait = Testcontainers::Wait::for_http('/api',
        port        => '8080/tcp',
        status_code => 204,
        method      => 'POST',
        tls         => 1,
    );
    is($wait->path, '/api', 'path');
    is($wait->port, '8080/tcp', 'port');
    is($wait->status_code, 204, 'status_code');
    is($wait->method, 'POST', 'method');
    ok($wait->tls, 'tls');
};

subtest 'for_log with string' => sub {
    my $wait = Testcontainers::Wait::for_log('ready');
    isa_ok($wait, 'Testcontainers::Wait::Log');
    is($wait->pattern, 'ready', 'pattern set');
    is($wait->occurrences, 1, 'default occurrences');
};

subtest 'for_log with regex' => sub {
    my $regex = qr/listening on port \d+/;
    my $wait = Testcontainers::Wait::for_log($regex, occurrences => 3);
    isa_ok($wait, 'Testcontainers::Wait::Log');
    is(ref($wait->pattern), 'Regexp', 'pattern is regex');
    is($wait->occurrences, 3, 'custom occurrences');
};

subtest 'for_health_check' => sub {
    my $wait = Testcontainers::Wait::for_health_check();
    isa_ok($wait, 'Testcontainers::Wait::HealthCheck');
};

subtest 'for_all' => sub {
    my $wait = Testcontainers::Wait::for_all(
        Testcontainers::Wait::for_listening_port('80/tcp'),
        Testcontainers::Wait::for_log('ready'),
    );
    isa_ok($wait, 'Testcontainers::Wait::Multi');
    is(scalar @{$wait->strategies}, 2, 'two strategies');
};

# Test Log check method with mock data
subtest 'log check method' => sub {
    my $wait = Testcontainers::Wait::Log->new(pattern => 'ready');

    # Create a mock container
    {
        package MockContainer;
        sub new { bless {logs => $_[1]}, $_[0] }
        sub logs { return $_[0]->{logs} }
    }

    my $container_yes = MockContainer->new("server starting...\nready to accept\n");
    ok($wait->check($container_yes), 'found in logs');

    my $container_no = MockContainer->new("server starting...\n");
    ok(!$wait->check($container_no), 'not found in logs');
};

subtest 'log check regex' => sub {
    my $wait = Testcontainers::Wait::Log->new(pattern => qr/port (\d+)/);

    {
        package MockContainer2;
        sub new { bless {logs => $_[1]}, $_[0] }
        sub logs { return $_[0]->{logs} }
    }

    my $c = MockContainer2->new("listening on port 5432\n");
    ok($wait->check($c), 'regex match found');
};

subtest 'log check occurrences' => sub {
    my $wait = Testcontainers::Wait::Log->new(
        pattern     => 'ready',
        occurrences => 2,
    );

    {
        package MockContainer3;
        sub new { bless {logs => $_[1]}, $_[0] }
        sub logs { return $_[0]->{logs} }
    }

    my $once = MockContainer3->new("ready\n");
    ok(!$wait->check($once), 'only 1 occurrence, need 2');

    my $twice = MockContainer3->new("ready\nstuff\nready\n");
    ok($wait->check($twice), '2 occurrences found');
};

# Test error on missing required args
subtest 'error handling' => sub {
    eval { Testcontainers::Wait::for_listening_port() };
    like($@, qr/Port required/, 'for_listening_port requires port');

    eval { Testcontainers::Wait::for_log() };
    like($@, qr/Log pattern required/, 'for_log requires pattern');

    eval { Testcontainers::Wait::for_all() };
    like($@, qr/At least one strategy/, 'for_all requires strategies');
};

done_testing;
