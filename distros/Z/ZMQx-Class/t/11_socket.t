use strict;
use warnings;
use 5.010;

use Test::Most;

use ZMQx::Class;
use ZMQ::Constants ':all';

my $context = ZMQx::Class->context;
my $port = int(rand(64)).'025';
diag("running zmq on port $port");

my $socket = ZMQx::Class->socket($context, 'PULL' );

subtest 'plain old set/getsockopt' => sub {
    my $val = 50;
    my $got;

    lives_ok{ $socket->setsockopt(ZMQ_SNDHWM,$val) } 'setsockopt';
    lives_ok{ $got = $socket->getsockopt(ZMQ_SNDHWM) } 'getsockopt';
    is($got,$val,'got value back');
};

subtest 'nice set/get methods' => sub {
    my $val = 75;
    my $got;

    lives_ok{ $socket->set_sndhwm($val) } 'set_sndhwm';
    lives_ok{ $got = $socket->get_sndhwm } 'get_sndhwm';
    is($got,$val,'got value back');

    is($socket->type,'PULL', '$socket->type');
};

subtest 'set after connect works' => sub {
    my $val = 75;
    my $got;

    lives_ok{ $socket->set_linger($val) } 'set_linger';
    lives_ok{ $got = $socket->get_linger } 'get_linger';
    is($got,$val,'got value back');
};

subtest 'warn after connect' => sub {
    my $sock = ZMQx::Class->socket('PULL', bind =>'tcp://*:'.($port+1) );
    warning_is { $sock->set_sndhwm(12); } "Setting 'ZMQ_SNDHWM' only works before connect/bind. Value not stored!", 'got a warning';
    is($sock->get_sndhwm,'1000','get did not work');
};

subtest 'subscribe on noSUB' => sub {
    my $sock = ZMQx::Class->socket('REQ');
    throws_ok { $sock->subscribe('foo') } qr/subscribe only works on SUB/,'subscribe only works on SUB';
    my $sock2 = ZMQx::Class->socket('SUB');
    throws_ok { $sock2->subscribe() } qr/required parameter.*missing/,'subcribe missing';
};

subtest 'deprecated' => sub {
    my $sock = ZMQx::Class->socket('PULL', bind =>'tcp://*:'.($port+1) );
    warning_like { $sock->get_fh() } qr/DEPRECATED/,'get_fh() is deprecated';
};

subtest 'deprecated' => sub {
    my $sock = ZMQx::Class->socket('PULL', bind =>'tcp://*:'.($port+1) );
    warning_like { $sock->receive_multipart() } qr/DEPRECATED/,'receive_multipart() is deprecated';
};

done_testing();

