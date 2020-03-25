use 5.012;
use warnings;
use lib 't/lib'; use MyTest;
use Net::SockAddr;
use UniEvent;
use Socket 'IPPROTO_IP';

my $loop = UniEvent::Loop->default_loop;

my $s = new UniEvent::Tcp;
$s->bind_addr(SA_LOOPBACK_ANY);
$s->listen;
$s->connection_callback(sub {
    my (undef, $client) = @_;
    $client->read_callback(sub {
        my (undef, $data) = @_;
        pass "server: read $data";
        $client->write($data+1);
        $client = undef;
    });
    pass "server: connection";
});
my $sa = $s->sockaddr;

my $sock = MyTest::create_socket(AF_INET, SOCK_STREAM, IPPROTO_IP);
MyTest::connect_socket($sock, $sa);

my $client = new UniEvent::Tcp;
$client->open($sock);
MyTest::close_socket($sock);

$client->write('1');

$client->read_callback(sub {
    my (undef, $data) = @_;
    pass "client: read";
    is $data, 2;
    $s->reset;
});

$loop->run;

done_testing(4);
