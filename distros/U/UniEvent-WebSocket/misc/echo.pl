use 5.012;
use warnings;
use UniEvent::WebSocket;

my $srv = UniEvent::WebSocket::Server->new({
    locations  => [{host => "dev", port => 6666}],
    connection => {check_utf8 => 1},
});
$srv->run;

$srv->connection_callback(sub {
    my (undef, $client) = @_;

    $client->message_callback(sub {
        my (undef, $msg) = @_;

        $client->send(payload => $msg->payload || '', opcode => $msg->opcode, deflate => 1);
    });
});

UE::Loop->default_loop->run;
