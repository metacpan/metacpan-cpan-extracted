use Test::More;
use Test::Exception;

use Test::Net::RabbitMQ;

my $mq = Test::Net::RabbitMQ->new;
isa_ok($mq, 'Test::Net::RabbitMQ', 'instantiated');

ok(!$mq->connected, 'not connected');
$mq->connect;
ok($mq->connected, 'connected');
$mq->disconnect;
ok(!$mq->connected, 'disconnect not connected');

$mq->connectable(0);

dies_ok { $mq->connect } 'no connect when !connectable';

$mq->connectable(1);

lives_ok { $mq->connect } 'can connect when connectable';

done_testing;