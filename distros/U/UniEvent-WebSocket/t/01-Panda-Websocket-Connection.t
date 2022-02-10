use 5.012;
use warnings;
use Test::More;
use lib 't/lib'; use MyTest;

{
    package Flogs::GetLogs::Connection;
    use parent 'UniEvent::WebSocket::ServerConnection';
}

my $loop = UE::Loop->default_loop;
my $state = 0;
my $send_cb = 0;
my ($server, $port) = MyTest::make_server();

my $conns = $server->connections();
while (my $c = $conns->next()) {
    warn(defined($c));
}

$server->handshake_callback(sub {
    my (undef, $conn, $creq) = @_;
    bless $conn, 'Flogs::GetLogs::Connection';
    my $auth = $creq->header('MyAuth');
    if ($auth && $auth eq 'MyPass') {
        $conn->send_accept_error({
            code => 403,
            message => 'fuck off',
        });
    }
});

$server->connection_event->add(sub {
    my ($serv, $conn) = @_;
    is(ref($conn), 'Flogs::GetLogs::Connection');
    $conn->send({deflate => 1, payload => 'Hey!', cb => sub { $send_cb = 1;} });

    $serv->foreach_connection(sub {
        my $conn = shift;
        is(ref($conn), 'Flogs::GetLogs::Connection');
    });
    my $conns = $serv->connections();
    while (my $c = $conns->next()) {
        ok defined $c;
        is(ref($c), 'Flogs::GetLogs::Connection');
    }
    is ($conn, $serv->get_connection($conn->id()));
});

$server->disconnection_event->add(sub {
    $state++;
    $loop->stop();
});

{
    my $client = MyTest::make_client($port);
    
    $client->message_event->add(sub {
        my ($client, $msg) = @_;
        is ref($client), "UniEvent::WebSocket::Client";
        $state++;
        ok ($msg->payload eq 'Hey!');
        $client->close(UE::WebSocket::CLOSE_DONE);
    });

    $server->run();
    $loop->run();

}
ok($state == 2);
is $send_cb, 1;

done_testing();
