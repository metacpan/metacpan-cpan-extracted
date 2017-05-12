use strict;
use warnings;
use Test::More 0.98;
use Test::TCP;

use Redis;
use Test::RedisServer;

eval { Test::RedisServer->new } or plan skip_all => 'redis-server is required in PATH to run this test';

# unix socket by default
my $server = Test::RedisServer->new;
ok $server->pid, 'pid ok';

my %connect_info = $server->connect_info;
like $connect_info{sock}, qr{/redis\.sock$}, 'unix socket ok';
ok !$connect_info{server}, 'server key does not exist ok';

my $redis = Redis->new(%connect_info);
is $redis->ping, 'PONG', 'ping pong ok';

$server->stop;
is $server->pid, undef, 'pid removed ok';
is $redis->ping, undef, 'no server available ok';

# port
my $port = empty_port();
$server = Test::RedisServer->new(conf => {
    bind => '127.0.0.1',
    port => $port,
});
ok $server->pid, 'pid ok';

%connect_info = $server->connect_info;
ok !$connect_info{sock}, 'sock does not exist ok';
is $connect_info{server}, '127.0.0.1:' . $port, 'server addr ok';

$redis = Redis->new(%connect_info);
is $redis->ping, 'PONG', 'ping pong ok';

undef $server;

is $redis->ping, undef, 'server died ok';

done_testing;
