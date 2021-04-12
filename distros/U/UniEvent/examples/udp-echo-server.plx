use 5.12.0;
use warnings;
use UniEvent;

# Simple echo server in udp
# perl examples/udp-echo-server.plx 1234
#
# Can be tested via:
# - nc -u 127.0.0.1 1234
# - perl examples/udp-echo-client.plx 1234
#

my ($port) = @ARGV;
$port //= 9999;

my $server = UniEvent::Udp->new;
$server->bind('127.0.0.1', $port);

say "$$ listening on port $port";

$server->recv_start;
$server->receive_callback(sub {
    my ($server, $data, $peer_addr, $flags, $error_code) = @_;
    if ($error_code) {
        say "receive error  :: $error_code";
        $server->loop->stop;
    }
    say "client ", $peer_addr, " has sent us ", length($data), " bytes";
    $server->send($data, $peer_addr);
});

$server->loop->run;
