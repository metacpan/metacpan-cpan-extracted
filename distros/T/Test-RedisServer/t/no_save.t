use strict;
use warnings;
use Test::More;
use File::Temp;
use File::Path 'remove_tree';
use Redis;

use Test::RedisServer;

eval { Test::RedisServer->new } or plan skip_all => 'redis-server is required in PATH to run this test';

subtest 'stop does not block when tmpdir is removed before stop' => sub {
    my $tmpdir = File::Temp->newdir;
    my $server = Test::RedisServer->new(tmpdir => $tmpdir);
    ok $server->pid, 'pid ok';

    remove_tree($tmpdir);
    ok ! -d $tmpdir;

    $server->stop;
    pass 'redis exit ok';
};

subtest 'normal stop saves dump.rdb when tmpdir exists' => sub {
    my $tmpdir = File::Temp->newdir;
    my $server = Test::RedisServer->new(tmpdir => $tmpdir);
    ok $server->pid, 'pid ok';

    my $redis = Redis->new($server->connect_info);
    $redis->set(foo => 'bar');

    $server->stop;
    ok -f "$tmpdir/dump.rdb", 'dump.rdb is created on normal stop';
};

done_testing;
