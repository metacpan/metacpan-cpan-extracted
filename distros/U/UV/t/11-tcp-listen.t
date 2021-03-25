use strict;
use warnings;

use UV::Loop ();
use UV::TCP ();

use Test::More;

use IO::Socket::INET;
use Socket;

sub sockaddr_port { (Socket::unpack_sockaddr_in $_[0])[0] }

my $tcp = UV::TCP->new;
isa_ok($tcp, 'UV::TCP');

$tcp->bind(Socket::pack_sockaddr_in(0, Socket::INADDR_LOOPBACK));

my $port = sockaddr_port($tcp->getsockname);

my $connection_cb_called;
sub connection_cb {
    my ($self) = @_;
    $connection_cb_called++;

    my $client = $self->accept;

    isa_ok($client, 'UV::TCP');

    $self->close;
    $client->close;
}

$tcp->listen(5, \&connection_cb);

my $sock = IO::Socket::INET->new(
    PeerHost => "127.0.0.1",
    PeerPort => $port,
) or die "Cannot connect socket - $@"; # yes $@

UV::Loop->default->run;

done_testing();
