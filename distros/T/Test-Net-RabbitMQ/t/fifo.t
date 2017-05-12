use Test::More;
use Test::Exception;

use Test::Net::RabbitMQ;

my $mq = Test::Net::RabbitMQ->new;
isa_ok($mq, 'Test::Net::RabbitMQ', 'instantiated');

$mq->connect;

$mq->channel_open(1);

$mq->exchange_declare(1, 'fifo');
$mq->queue_declare(1, 'new-fifo');

$mq->queue_bind(1, 'new-fifo', 'fifo', 'fifo.new');

$mq->publish(1, 'fifo.new', 'foo', { exchange => 'fifo' });
$mq->publish(1, 'fifo.new', 'bar', { exchange => 'fifo' });

$mq->consume(1, 'new-fifo');

my $msg = $mq->recv;
cmp_ok($msg->{body}, 'eq', 'foo', 'first recv matches first published');

$msg = $mq->recv;
cmp_ok($msg->{body}, 'eq', 'bar', 'second recv matches second published');

done_testing;
