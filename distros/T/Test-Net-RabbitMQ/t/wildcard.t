use Test::More;
use Test::Exception;

use Test::Net::RabbitMQ;

my $mq = Test::Net::RabbitMQ->new;
isa_ok($mq, 'Test::Net::RabbitMQ', 'instantiated');

$mq->connect;

$mq->channel_open(1);

$mq->exchange_declare(1, 'foo');
$mq->queue_declare(1, 'bar1');
$mq->queue_declare(1, 'bar2');
$mq->queue_declare(1, 'bar3');
$mq->queue_declare(1, 'bar4');

$mq->queue_bind(1, 'bar1', 'foo', 'foo.bar');
$mq->queue_bind(1, 'bar2', 'foo', 'foo.*.zot');
$mq->queue_bind(1, 'bar3', 'foo', 'foo.#.zot');
$mq->queue_bind(1, 'bar4', 'foo', 'foo.#');

$mq->publish(1, 'foo.bar', 'hello!', { exchange => 'foo' });
my $msg = $mq->get(1, 'bar1', {});
cmp_ok($msg->{body}, 'eq', 'hello!', 'get got the message (foo.bar)');

my $msg2 = $mq->get(1, 'bar4', {});
cmp_ok($msg2->{body}, 'eq', 'hello!', 'get got the message in the wildcard queue (foo.bar)');

$mq->publish(1, 'foo.ass.zot', 'hello!', { exchange => 'foo' });
my $msg3 = $mq->get(1, 'bar2', {});
cmp_ok($msg3->{body}, 'eq', 'hello!', 'get got foo.*.zot message (foo.ass.zot)');
my $msg4 = $mq->get(1, 'bar3', {});
cmp_ok($msg4->{body}, 'eq', 'hello!', 'get got foo.#.zot message (foo.ass.zot)');

$mq->publish(1, 'foo.ass.hat.zot', 'hello!', { exchange => 'foo' });
my $msg5 = $mq->get(1, 'bar4', {});
cmp_ok($msg5->{body}, 'eq', 'hello!', 'get got foo.# message (foo.ass.hat.zot)');

my $msg6 = $mq->get(1, 'bar3', {});
cmp_ok($msg6->{body}, 'eq', 'hello!', 'get got foo.#.zot message (foo.ass.hat.zot)');

my $msg7 = $mq->get(1, 'bar2', {});
ok(!defined($msg7->{body}), 'get did not get foo.*.zot message (foo.ass.hat.zot)');

done_testing;
