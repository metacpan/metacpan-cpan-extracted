use 5.020;
use warnings;
use UniEvent::Socks;
use UniEvent::HTTP qw/http_request/;

$SIG{PIPE} = 'IGNORE';
my $MPORT = 6669;
my @foo;

my $zt = UE::Timer->new; $zt->start(0.3); $zt->callback(sub {
    con($_) for (@foo);
});

my $t = UE::Timer->new; $t->start(0.01); $t->callback(sub {
sub con {
    my $z=shift;

    $z->write("shit", sub {undef $z});
    $z->shutdown;
}

sub dis { shift->reset }

my $sock = UE::Tcp->new;
$sock->connect("dev", $MPORT);
$sock->write("GET /chat HTTP/1.1\r\nUpgrade: websocket\r\nConnection: Upgrade\r\nSec-WebSocket-Key: x3JJHMbDL1EzLkh9GBhXDw==\r\nSec-WebSocket-Version: 13\r\n\r", sub {});
$sock->write("\n2\r\nab\r");
$sock->write("\n", sub {

#warn "OK";

    $_[0]->reset;
    $_[0]->write("666");
    $_[0]->connect("dev", $MPORT, sub {shift->disconnect});

    $_[0]->connect("dev", $MPORT, 0.005, sub {$_[0]->disconnect; shift->connect("127.0.0.1", $MPORT)});
    $_[0]->write("666");

    $_[0]->connect("dev", $MPORT, 0.005);
    $_[0]->reset;

    $_[0]->write("666");
});

push @foo, $sock;

});

UE::Loop->default_loop->run;