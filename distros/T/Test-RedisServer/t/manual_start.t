use strict;
use warnings;
use Test::More;

use Redis;
use Test::RedisServer;

eval { Test::RedisServer->new } or plan skip_all => 'redis-server is required in PATH to run this test';

my $server = Test::RedisServer->new( auto_start => 0 );

my $redis;
eval {
    $redis = Redis->new($server->connect_info);
};
ok !$redis, 'redis client object was not created ok';
like $@, qr/Could not connect to Redis server/, 'error msg ok';

$server->start;

$redis = Redis->new($server->connect_info);

is $redis->ping, 'PONG', 'ping pong ok';

done_testing;
