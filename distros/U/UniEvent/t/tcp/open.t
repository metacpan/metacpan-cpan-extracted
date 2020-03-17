use 5.012;
use warnings;
use lib 't/lib'; use MyTest;
use Net::SockAddr;
use UniEvent;

my $loop = UniEvent::Loop->default_loop;

my $s = new UniEvent::Tcp;
$s->bind_addr(SA_LOOPBACK_ANY);
$s->listen;
$s->connection_callback(sub {
    my (undef, $client) = @_;
    $client->read_callback(sub {
        my (undef, $data) = @_;
        pass "server: read";
        $client->write($data+1);
        $client = undef;
    });
    pass "server: connection";
});
my $sa = $s->sockaddr;

socket my $sock, AF_INET, SOCK_STREAM, 0;
connect($sock, $sa->get) or die "$!";

my $client = new UniEvent::Tcp;
$client->open($sock);
close $sock;
undef $sock;
$client->write('1');
$client->read_callback(sub {
    my (undef, $data) = @_;
    pass "client: read";
    is $data, 2;
    $s->reset;
});

$loop->run;

done_testing(4);
