use Test::More;
use Test::Exception;

use Test::Net::RabbitMQ;

my $mq = Test::Net::RabbitMQ->new;
isa_ok($mq, 'Test::Net::RabbitMQ', 'instantiated');

dies_ok { $mq->channel_open } 'channel_open fails if not connected';

$mq->connect;

$mq->channel_open(1);

dies_ok { $mq->channel_close(12) } 'channel_close dies on invalid channel';

lives_ok { $mq->channel_close(1) } 'channel_close lives on valid channel';

done_testing;