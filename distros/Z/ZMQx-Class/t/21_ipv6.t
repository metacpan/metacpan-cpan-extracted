use strict;
use warnings;
use 5.010;

use Test::Most;

use ZMQx::Class;

my $context = ZMQx::Class->context;
my $port = int(rand(64)).'025';
diag("running zmq on port $port");

subtest 'push-pull using ipv6' => sub {
    my $pull = ZMQx::Class->socket($context, 'PULL', bind =>'tcp://::1:'.$port , { ipv4only=>0 });
    my $push = ZMQx::Class->socket($context, 'PUSH', connect =>'tcp://::1:'.$port, { ipv4only=>0 });
    $push->send(['Hallo Welt']);
    my $got = $pull->receive('blocking');
    cmp_deeply($got,['Hallo Welt'],'push-pull');
};

done_testing();

