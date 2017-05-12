use Test::More;
use Test::Exception;

use Test::Net::RabbitMQ;

my $mq = Test::Net::RabbitMQ->new;
isa_ok($mq, 'Test::Net::RabbitMQ', 'instantiated');

$mq->connect;

$mq->channel_open(1);

$mq->exchange_declare(1, 'ex');
my ($queue_name, $msg_count, $consumer_count)
    = $mq->queue_declare(1, 'bind-twice');
is($queue_name, 'bind-twice', 'queue_declare returns given queue name');
is($msg_count, 0, 'queue_declare returns message count of 0 for new queue');
is($consumer_count, 0, 'queue_declare returns consumer count of 0 for new queue');

is_deeply(
    [ $mq->queue_declare(1, 'bind-twice', { passive => 1 }) ],
    [ 'bind-twice', 0, 0 ],
    'queue_declare with passive => 1'
);

$mq->queue_bind(1, 'bind-twice', 'ex', 'key');
$mq->publish(
    1, 'key', 'message body',
    { exchange     => 'ex' },
    { content_type => 'text/plain' }
);

is_deeply(
    [ $mq->queue_declare(1, 'bind-twice', { passive => 1 }) ],
    [ 'bind-twice', 1, 0 ],
    'queue_declare with passive => 1 has a message'
);

$mq->queue_declare(1, 'bind-twice');

my $msg = $mq->get(1, 'bind-twice');
ok($msg, 'got message after calling queue_declare');
is($msg->{body}, 'message body', 'message body contains expected content');

lives_ok { $mq->queue_delete(1, 'bind-twice') } 'queue_delete';
lives_ok { $mq->exchange_delete(1, 'bind-twice') } 'ex';

done_testing;
