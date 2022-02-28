use strict;
use warnings;
use Test::More;
use File::Path 'remove_tree';

use Test::RedisServer;

eval { Test::RedisServer->new } or plan skip_all => 'redis-server is required in PATH to run this test';

my $tmpdir = File::Temp->newdir;
my $server = Test::RedisServer->new(tmpdir => $tmpdir);
ok $server->pid, 'pid ok';

remove_tree($tmpdir);
ok ! -f $tmpdir;

$server->stop;
pass 'redis exit ok';

done_testing;
