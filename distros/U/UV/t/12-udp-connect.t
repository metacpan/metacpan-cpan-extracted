use v5.14;
use warnings;

use UV::Loop ();
use UV::UDP ();

use Test::More;

use IO::Socket::INET;
use Socket;

my $recvsock = IO::Socket::INET->new(
    LocalHost => "127.0.0.1",
    LocalPort => 0,
    Proto     => "udp",
) or die "Cannot create recv socket - $@"; # yes $@
my $port = $recvsock->sockport;

my $udp = UV::UDP->new;
isa_ok($udp, 'UV::UDP');

$udp->connect(Socket::pack_sockaddr_in($port, Socket::INADDR_LOOPBACK));

is((Socket::unpack_sockaddr_in($udp->getpeername))[0], $port,
    'getpeername returns sockaddr');

done_testing();
