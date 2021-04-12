use 5.12.0;
use warnings;
use UniEvent;
use Net::SockAddr;

# This is simple udp echo client. "Simple" means, that it executes either
# blocking code (reading stdin) or async code (UE loop run). It has
# the drawback, if something happen with server, when client is in blocking
# mode (e.g. disconnect), it will not know about that until it send a line.

# Command line to launch:
# perl examples/udp-echo-client.plx 1234

my ($port) = @ARGV;
$port //= 9999;

my $client = UniEvent::Udp->new;
my $dest = Net::SockAddr::Inet4->new("127.0.0.1", $port);

$client->receive_callback(sub {
    my ($server, $data, $peer_addr, $flags, $error_code) = @_;
    die("reading data error: $error_code\n") if $error_code;
    say "[<<] ", $data;
    $client->loop->stop;
});
$client->recv_start;

while(my $line = <STDIN>) {
    chomp($line);
    say "[read] ", $line;
    $client->send($line, $dest, sub {
        my ($client, $error_code) = @_;
        die("writing data error: $error_code\n") if $error_code;
        say "[>>] ", $line;
    });
    $client->loop->run;
}
say "normal exit";