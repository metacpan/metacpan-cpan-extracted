use Test::More;
use Test::Exception;

use Test::Net::RabbitMQ;

my $mq = Test::Net::RabbitMQ->new;
isa_ok($mq, 'Test::Net::RabbitMQ', 'instantiated');

$mq->connect;

$mq->channel_open(1);

$mq->exchange_declare(1, 'ack');
$mq->queue_declare(1, 'ack');

$mq->queue_bind(1, 'ack', 'ack', 'ack');

# This test currently only tests that ack()ing is not supported.  If/when
# ack()ing is added then this test should be updated to test that ack()
# works.  Also, the tx.t test should be updated to test that ack()s are
# properly committed and rolled back.

dies_ok  { $mq->consume(1, 'ack', {no_ack=>0}) } 'consume fails with no_ack=>0';
lives_ok { $mq->consume(1, 'ack', {no_ack=>1}) } 'consume lives with no_ack=>1';

done_testing;
