#!perl

use Test::More tests => 7;
use strict;
use warnings;

BEGIN {
    use_ok( 'ZeroMQ::PubSub' ) || print "Bail out!\n";
    use_ok( 'ZeroMQ::PubSub::Client' ) || print "Bail out!\n";
    use_ok( 'ZeroMQ::PubSub::Server' ) || print "Bail out!\n";
}

my $server = ZeroMQ::PubSub::Server->new(
    publish_addrs   => [ 'tcp://0.0.0.0:63123' ],
    subscribe_addrs => [ 'tcp://0.0.0.0:63124' ],
    debug           => 0,
);

my $start_time = time();

# called when server receives ping
$server->subscribe(ping => sub {
    my ($self, $params) = @_;
    is($params->{time}, $start_time, "Publish message received");
});

my $pub_sock = $server->bind_publish_socket;
my $sub_sock = $server->bind_subscribe_socket;

my $client_ping_subscribed_count = 0;
my @clients;

my $client1 = subscribe_client();
my $client2 = subscribe_client();

# publish ping event
$client1->publish( ping => { 'time' => $start_time } );

# server receive ping
$server->poll_once;

# wait to receive our ping
$_->poll_once for @clients;

# make sure all clients received messages
is($client_ping_subscribed_count, scalar(@clients), "All clients received broadcast");

# done!
done_testing();

sub subscribe_client {
    my $client = ZeroMQ::PubSub::Client->new(
        publish_address   => 'tcp://127.0.0.1:63123',
        subscribe_address => 'tcp://127.0.0.1:63124',
        debug             => 0,
    );

    # called when we receive our ping back
    $client->subscribe(ping => sub {
        my ($self, $params) = @_;
        $client_ping_subscribed_count++;
        is($params->{time}, $start_time, "Round trip message received");
    });

    push @clients, $client;

    return $client;
}
