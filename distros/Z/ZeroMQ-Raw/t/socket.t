use strict;
use warnings;
use Test::More;
use Test::Exception;

use ZeroMQ::Raw;
use ZeroMQ::Raw::Constants qw(ZMQ_PUB ZMQ_SUB ZMQ_SUBSCRIBE ZMQ_NOBLOCK);

my $c = ZeroMQ::Raw::Context->new(threads => 0);
ok $c, 'got context';
ok $c->has_valid_context, 'is allocated';

my $pub = ZeroMQ::Raw::Socket->new($c, ZMQ_PUB);
ok $pub, 'got publisher';
ok $pub->is_allocated, 'socket is allocated';

throws_ok {
    my $bad = ZeroMQ::Raw::Socket->new($c, ZMQ_PUB);
    $bad->bind("OHNOES://IMDYING!");
} qr/protocol is not supported/, 'make sure errors die';

lives_ok {
    $pub->bind("inproc://test");
} 'bind works';

my $sub = ZeroMQ::Raw::Socket->new($c, ZMQ_SUB);
ok $sub, 'got subscriber';
ok $sub->is_allocated, 'subscriber is allocated';

lives_ok {
    $sub->connect("inproc://test");
} 'connected to publisher ok';

lives_ok {
    $sub->setsockopt(ZMQ_SUBSCRIBE, 'LOL.CATS');
} 'set socket option';

my $to_send = ZeroMQ::Raw::Message->new_from_scalar('LOL.CATS are awesome');

lives_ok {
    $pub->send($to_send, ZMQ_NOBLOCK);
} 'sent ok';

my $to_recv = ZeroMQ::Raw::Message->new;
lives_ok {
    $sub->recv($to_recv, ZMQ_NOBLOCK);
} 'recv without error';

is $to_recv->data, 'LOL.CATS are awesome', 'got expected data';

done_testing;
