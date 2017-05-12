use strict;
use warnings;
use 5.010;

use Test::Most;
use ZMQx::Class;
use AnyEvent;
use Data::Dumper;
use ZMQ::Constants qw(ZMQ_DONTWAIT);

my $context = ZMQx::Class->context;

{   # AnyEvent pub-sub
    my $port = int(rand(64)+1).'025';
    diag("running zmq on port $port");
    my $server = ZMQx::Class->socket($context, 'PUB', bind =>'tcp://*:'.$port );

    my $client1 = ZMQx::Class->socket($context, 'SUB', connect =>'tcp://localhost:'.$port );
    $client1->subscribe('');
    my $done1 = AnyEvent->condvar;
    my @got1;
    my $watcher1 = $client1->anyevent_watcher(sub {
        while (my $msgs = $client1->receive) {
            push(@got1,$msgs);
            $done1->send if @got1 >= 2;
        }
    });

    my $client2 = ZMQx::Class->socket($context, 'SUB', connect =>'tcp://localhost:'.$port );
    $client2->subscribe('222');
    my $done2 = AnyEvent->condvar;
    my @got2;
    my $watcher2 = $client2->anyevent_watcher(sub {
        while (my $msgs = $client2->receive) {
            push(@got2,$msgs);
            $done2->send if @got2 >= 1;
        }
    });

    sleep(1);

    my @send_1 = ('Hello','World');
    $server->send(\@send_1);

    my @send_2 = ('222','foo');
    $server->send(\@send_2);

    $done1->recv;
    $done2->recv;

    is(@got1,2,'client 1 got 2 messages');
    is(@got2,1,'client 2 got 1 message');

    cmp_deeply($got1[0],\@send_1,'client 1 first message = Hello World');
    cmp_deeply($got1[1],\@send_2,'client 1 second message = 222 foo');
    cmp_deeply($got2[0],\@send_2,'client 2 first message = 222 foo');
}

{   # AnyEvent req-rep using wait_for_message
    my $port = int(rand(64)+1).'025';
    diag("running zmq on port $port");
    my $message = "Hello";

    my $server = ZMQx::Class->socket($context, 'REP', bind =>'tcp://*:'.$port );

    my $client = ZMQx::Class->socket($context, 'REQ', connect =>'tcp://localhost:'.$port );
    $client->send([$message]);

    my $server_got = $server->receive(1);
    cmp_deeply($server_got,[$message],'Server got message');
    $server->send(['ok',@$server_got],ZMQ_DONTWAIT);
    sleep(1);
    my $res = $client->receive(1);

    cmp_deeply($res,['ok',$message],'Client got response from server');
}


done_testing();

