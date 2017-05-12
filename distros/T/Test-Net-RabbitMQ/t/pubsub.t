use Test::More;
use Test::Exception;

use Test::Net::RabbitMQ;

my $mq = Test::Net::RabbitMQ->new;
isa_ok($mq, 'Test::Net::RabbitMQ', 'instantiated');

$mq->connect;

$mq->channel_open(1);

$mq->exchange_declare(1, 'order');
$mq->queue_declare(1, 'new-orders');

$mq->queue_bind(1, 'new-orders', 'order', 'order.new');

$mq->publish(1, 'order.new', 'hello!', { exchange => 'order' });

my $ctag = $mq->consume(1, 'new-orders');
like($ctag, qr/^[\w-]+$/, 'got a sane consumer tag back from consume');

my $msg = $mq->recv;
cmp_ok($msg->{body}, 'eq', 'hello!', 'recv got the message');
ok(exists $msg->{redelivered}, 'msg has redelivered key');

ok($mq->cancel(1, $ctag), 'cancel');
ok(!$mq->cancel(1, $ctag), 'cancel returns false without a matching consume');

dies_ok { $mq->cancel } 'must provide a channel to cancel';
dies_ok { $mq->cancel(1) } 'must provide a consumer tag to cancel';
dies_ok { $mq->cancel(1, undef) } 'must provide a non-undef consumer tag to cancel';

$mq->publish(1, 'order.new', 'hello!', { exchange => 'order' });

my $msg2 = $mq->get(1, 'new-orders', {});
cmp_ok($msg2->{body}, 'eq', 'hello!', 'get got the message');

$mq->disconnect;

for my $meth (qw( publish consume recv cancel ) ) {
    dies_ok { $mq->$meth } "cannot call $meth if not connected";
}

done_testing;
