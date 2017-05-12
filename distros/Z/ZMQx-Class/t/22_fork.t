use strict;
use warnings;
use 5.010;

use Test::Most tests => 6; # done_testing() not working with fork
use Test::SharedFork;
use ZMQx::Class;

my $port = int(rand(63)+1).'025';
diag("running zmq on port $port");
my $parent_context = ZMQx::Class->context;

# start client, communicate, then fork
# (this happens if you init a model in catalyst that does some 0mq on startup
# then gets forked and does more 0mq)

my $server = ZMQx::Class->socket('REP', bind =>'tcp://*:'.$port );
my $client = ZMQx::Class->socket('REQ', connect =>'tcp://localhost:'.$port );

{   # before fork
    $client->send(['hello from parent']);
    my $req = $server->receive(1);
    $server->send(['ok']);
    my $ok = $client->receive(1);

    is($req->[0],'hello from parent','before fork: server got req');
    is($ok->[0], 'ok', 'before fork: client got ok');
};

my $child_pid = fork();
if ($child_pid) {
    # parent process,
    my $got = $server->receive(1);
    is($got->[0],'from forked child','after fork: parent: server got req');
    $server->send(['ok']);
    waitpid($child_pid, 0);
}
else {
    # child process
    my $child_context = ZMQx::Class->context;
    isnt("$child_context","$parent_context","after fork: child has other context");

    $client->send(['from forked child']);
    my $reply = $client->receive(1);
    is($reply->[0],'ok','after fork: child: got reply');

    is($client->_pid, $$, 'after fork: new _pid');
}

