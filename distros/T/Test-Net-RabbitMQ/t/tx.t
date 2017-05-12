use Test::More;
use Test::Exception;

use Test::Net::RabbitMQ;

my $mq = Test::Net::RabbitMQ->new;
isa_ok($mq, 'Test::Net::RabbitMQ', 'instantiated');

dies_ok { $mq->tx_select   } 'tx_select fails if not connected';
dies_ok { $mq->tx_commit   } 'tx_commit fails if not connected';
dies_ok { $mq->tx_rollback } 'tx_rollback fails if not connected';

$mq->connect;

dies_ok { $mq->tx_select(1)   } 'tx_select fails on undeclared channel';
dies_ok { $mq->tx_commit(1)   } 'tx_commit fails on undeclared channel';
dies_ok { $mq->tx_rollback(1) } 'tx_rollback fails on undeclared channel';

$mq->channel_open(1);

dies_ok { $mq->tx_commit(1)   } 'tx_commit fails outside of a transaction';
dies_ok { $mq->tx_rollback(1) } 'tx_rollback fails outside of a transaction';

$mq->exchange_declare(1, 'tx');
$mq->queue_declare(1, 'tx');

$mq->queue_bind(1, 'tx', 'tx', 'tx');

$mq->tx_select(1);
$mq->publish(1, 'tx', 'bad', { exchange => 'tx' });
$mq->tx_rollback(1);

$mq->tx_select(1);
$mq->publish(1, 'tx', 'good', { exchange => 'tx' });
$mq->tx_commit(1);

$mq->consume(1, 'tx');

my $msg = $mq->recv;
cmp_ok($msg->{body}, 'eq', 'good', 'first recv matches committed publish');

$msg = $mq->recv;
is($msg, undef, 'second recv is empty');

done_testing;
