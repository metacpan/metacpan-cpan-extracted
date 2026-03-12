use strict;
use warnings;
use Redis;
use Test::More 0.98;
use Test::TCP;
use Test::ValkeyServer;

eval { Test::ValkeyServer->new } or plan skip_all => 'valkey-server is required in PATH to run this test';

my $cli_version = `valkey-cli --version 2>&1`;
unless ($cli_version && $cli_version =~ /valkey-cli/) {
    plan skip_all => 'valkey-cli is required in PATH to run this test';
}

if ($cli_version =~ /(\d+)\.(\d+)/) {
    my ($major, $minor) = ($1, $2);
    unless ($major > 8 || ($major == 8 && $minor >= 1)) {
        plan skip_all => "valkey 8.1+ required for single-node cluster (have $major.$minor)";
    }
}

subtest 'basic cluster' => sub {
    my $port = empty_port();
    my $server = Test::ValkeyServer->new(
        cluster => 1,
        timeout => 10,
        conf    => { port => $port, bind => '127.0.0.1' },
    );
    ok $server->pid, 'pid ok';

    my $redis = Redis->new($server->connect_info);
    is $redis->ping, 'PONG', 'ping pong ok';

    my %connect = $server->connect_info;
    is $connect{server}, "127.0.0.1:$port", 'connect_info uses configured host and port';

    my $host = $server->conf->{bind};
    my $info = `valkey-cli -h $host -p $port cluster info 2>&1`;
    like $info, qr/cluster_state:ok/, 'cluster_state is ok';
    like $info, qr/cluster_known_nodes:1/, 'single node cluster';

    $server->stop;
    is $server->pid, undef, 'pid removed after stop';
};

subtest 'manual start with cluster' => sub {
    my $port = empty_port();
    my $server = Test::ValkeyServer->new(
        cluster    => 1,
        auto_start => 0,
        timeout    => 10,
        conf       => { port => $port, bind => '127.0.0.1' },
    );
    is $server->pid, undef, 'not started yet';

    $server->start;
    ok $server->pid, 'started manually';

    my $redis = Redis->new($server->connect_info);
    is $redis->ping, 'PONG', 'ping pong ok';

    $server->stop;
};

subtest 'exec with cluster croaks' => sub {
    my $port = empty_port();
    my $server = Test::ValkeyServer->new(
        cluster    => 1,
        auto_start => 0,
        timeout    => 10,
        conf       => { port => $port, bind => '127.0.0.1' },
    );
    eval { $server->exec };
    like $@, qr/cluster mode is not supported with exec/, 'exec croaks in cluster mode';
};

subtest 'cluster without bind' => sub {
    my $port = empty_port();
    my $server = Test::ValkeyServer->new(
        cluster => 1,
        timeout => 10,
        conf    => { port => $port },
    );
    ok $server->pid, 'pid ok';

    my $valkey = Redis->new($server->connect_info);
    is $valkey->ping, 'PONG', 'ping pong ok';

    my %connect = $server->connect_info;
    is $connect{server}, "127.0.0.1:$port", 'defaults to 127.0.0.1';

    $server->stop;
};

subtest 'cluster without port croaks' => sub {
    eval {
        Test::ValkeyServer->new(
            cluster    => 1,
            auto_start => 0,
        );
    };
    like $@, qr/cluster mode requires a port/, 'croaks without port';
};

subtest 'cluster with unixsocket croaks' => sub {
    eval {
        Test::ValkeyServer->new(
            cluster    => 1,
            auto_start => 0,
            conf       => { port => empty_port(), unixsocket => '/tmp/valkey.sock' },
        );
    };
    like $@, qr/cluster mode does not support unixsocket/, 'croaks with unixsocket';
};

done_testing;
