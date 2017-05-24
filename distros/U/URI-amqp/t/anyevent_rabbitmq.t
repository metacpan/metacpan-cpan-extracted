use strict;
use warnings;

use Test::More tests => 1;
use URI;

my $uri = URI->new(
'amqps://user:pass@host.avast.com:1234/vhost?heartbeat=10&connection_timeout=60&channel_max=11&frame_max=8192&verify=0&cacertfile=/etc/cert/ca'
);

#my $ar = AnyEvent::RabbitMQ->new->load_xml_spec()->connect(
#    host       => 'localhost',
#    port       => 5672,
#    user       => 'guest',
#    pass       => 'guest',
#    vhost      => '/',
#    timeout    => 1,
#    tls        => 0, # Or 1 if you'd like SSL
#    tune       => { heartbeat => 30, channel_max => $whatever, frame_max = $whatever },

is_deeply(
    $uri->as_anyevent_rabbitmq(),
    {
        host    => 'host.avast.com',
        user    => 'user',
        pass    => 'pass',
        port    => 1234,
        vhost   => 'vhost',
        timeout => 60,
        tls     => 1,
        tune    => {
            frame_max   => 8192,
            heartbeat   => 10,
            channel_max => 11,

        },
    },
    'as_anyevent_rabbitmq'
);
