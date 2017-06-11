use strict;
use warnings;

use Test::More tests => 2;
use URI;

subtest 'complex uri' => sub {
    my $uri = URI->new(
    'amqps://user:pass@host.avast.com:1234/vhost?heartbeat=10&connection_timeout=60&channel_max=11&frame_max=8192&verify=0&cacertfile=/etc/cert/ca'
    );
    
    my ($host, $options) = $uri->as_net_amqp_rabbitmq();
    is($host, 'host.avast.com', 'host');
    is_deeply(
        $options,
        {
            user            => 'user',
            password        => 'pass',
            port            => 1234,
            vhost           => 'vhost',
            channel_max     => 11,
            frame_max       => 8192,
            heartbeat       => 10,
            timeout         => 60,
            ssl             => 1,
            ssl_verify_host => 0,
            ssl_cacert      => '/etc/cert/ca',
        },
        'options'
    );

    done_testing(2);
};

subtest 'simple uri' => sub {
    my $uri = URI->new('amqp://localhost');

    my ($host, $options) = $uri->as_net_amqp_rabbitmq();
    is($host, 'localhost', 'host');
    is_deeply(
        $options,
        {
            port => 5672,
        },
        'options'
    );

    done_testing(2);
}
