use v5.14;
use warnings;

use UV::Loop ();
use UV::TCP ();

use Test::More;

use IO::Socket::INET;
use Socket;

my $listensock = IO::Socket::INET->new(
    LocalHost => "127.0.0.1",
    LocalPort => 0,
    Listen    => 1,
) or die "Cannot create listening socket - $@"; # yes $@
my $port = $listensock->sockport;

my $tcp = UV::TCP->new;
isa_ok($tcp, 'UV::TCP');

my $connect_cb_called;
my $req = $tcp->connect(Socket::pack_sockaddr_in($port, Socket::INADDR_LOOPBACK),
    sub { $connect_cb_called++ } );
isa_ok($req, 'UV::Req');

UV::Loop->default->run;

ok($connect_cb_called, 'connect callback was called');

is((Socket::unpack_sockaddr_in($tcp->getpeername))[0], $port,
    'getpeername returns sockaddr');

my $shutdown_cb_called;
$tcp->shutdown(sub { $shutdown_cb_called++ } );

UV::Loop->default->run;

ok($shutdown_cb_called, 'shutdown callback was called');

done_testing();
