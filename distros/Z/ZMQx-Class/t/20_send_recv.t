use strict;
use warnings;
use 5.010;

use Test::Most;

use ZMQx::Class;

my $context = ZMQx::Class->context;
my $port = int(rand(64)).'025';
diag("running zmq on port $port");

subtest 'push-pull tcp' => sub {
    my $pull = ZMQx::Class->socket($context, 'PULL', bind =>'tcp://*:'.$port );
    my $push = ZMQx::Class->socket($context, 'PUSH', connect =>'tcp://localhost:'.$port );
    $push->send(['Hallo','Welt']);
    my $got = $pull->receive('blocking');
    cmp_deeply($got,['Hallo','Welt'],'got message');
};

subtest 'push-pull inproc' => sub {
    my $pull = ZMQx::Class->socket($context, 'PULL', bind =>'inproc://foo');
    my $push = ZMQx::Class->socket($context, 'PUSH', connect =>'inproc://foo' );
    $push->send(['Hallo Welt']);
    my $got = $pull->receive('blocking');
    cmp_deeply($got,['Hallo Welt'],'got message');
};

subtest 'req-rep tcp' => sub {
    my $server = ZMQx::Class->socket($context, 'REP', bind =>'tcp://*:'.$port );
    my $client = ZMQx::Class->socket($context, 'REQ', connect =>'tcp://localhost:'.$port );

    my @send = ('Hello','World');
    $client->send(\@send);
    my $got = $server->receive('blocking');
    cmp_deeply($got,\@send,'got message');
};

subtest 'router-rep tcp' => sub {
    my $server = ZMQx::Class->socket($context, 'ROUTER', bind =>'tcp://*:'.$port );
    my $client = ZMQx::Class->socket($context, 'REQ', connect =>'tcp://localhost:'.$port );

    my @send = ('Hello','World');
    $client->send(\@send);
    my $got = $server->receive('blocking');
    my ($identifier,$null,@message) = @$got;
    is($null, '', "Null must be an empty string for generic identifiers");
    explain ($got);
    cmp_deeply(\@message,\@send,'got message');
};

subtest 'send a string' => sub {
    my $pull = ZMQx::Class->socket($context, 'PULL', bind =>'tcp://*:'.$port );
    my $push = ZMQx::Class->socket($context, 'PUSH', connect =>'tcp://localhost:'.$port );
    $push->send('Hallo Welt');
    my $got = $pull->receive('blocking');
    cmp_deeply($got,['Hallo Welt'],'got message');
};



done_testing();

