use strict;
use warnings;
use Test::More;

use Redis;
use Test::RedisServer;
use POSIX qw/SIGTERM/;

eval { Test::RedisServer->new } or plan skip_all => 'redis-server is required in PATH to run this test';

my $server = Test::RedisServer->new;

my $pid = fork;
die 'fork failed' unless defined $pid;

if ($pid == 0) {
    sleep 1;
    kill SIGTERM, $server->pid;
    exit(0);
}

$server->wait_exit;

pass 'process exited';
is $server->pid, undef, 'no pid ok';


$pid = fork;
die 'fork failed' unless defined $pid;

if ($pid == 0) {
    # child
    my $redis = Test::RedisServer->new;
    local $SIG{TERM} = sub { $redis->stop };
    $redis->wait_exit;
    exit(0);
}
else {
    sleep 1;
    kill SIGTERM, $pid;
    while (waitpid($pid, 0) >= 0) {
    }
    pass 'redis exit ok';
}



done_testing;
    
