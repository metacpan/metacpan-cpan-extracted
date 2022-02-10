use 5.012;
use UniEvent;

$SIG{PIPE} = 'IGNORE';

my $MHOST = 'dev';
my $MPORT = 6669;
my @foo;

my $zt = UE::Timer->new; $zt->start(0.3); $zt->callback(sub {
    con($_) for (@foo);
});

my $ztz = UE::Timer->new; $ztz->start(1); $ztz->callback(sub {
    @foo = ();
});

my $t = UE::Timer->new; $t->start(0.05); $t->callback(sub {

sub con {
    my $z=shift;

    $z->reset;

    $z->connect($MHOST, $MPORT);
    $z->write("shit", sub {undef $z});
    $z->shutdown;
}

my $sock = UE::Tcp->new;
$sock->use_ssl;

$sock->connect($MHOST, $MPORT);
$sock->write("GET /chat HTTP/1.1\r\nUpgrade: websocket\r\nConnection: Upgrade\r\nSec-WebSocket-Key: x3JJHMbDL1EzLkh9GBhXDw==\r\nSec-WebSocket-Version: 13\r\n\r", sub {});
$sock->write("\n2\r\nab\r");
$sock->write("\n", sub {
        $_[0]->write("666");
        $_[0]->write("666");
    $_[0]->disconnect;
    $_[0]->write("666");
    $_[0]->connect($MHOST, $MPORT, sub {
        $_[0]->reset;

        $_[0]->connect($MHOST, $MPORT, 0.005, sub {$_[0]->disconnect; shift->connect($MHOST, $MPORT)});
        $_[0]->write("666");

        $_[0]->connect($MHOST, $MPORT, 0.005);
        $_[0]->disconnect;

        $_[0]->write($MHOST);
    });
});

push @foo, $sock;

});

my $guard = UE::timer_once 5, sub {
    say "GUARD TIMER";
    UE::Loop->default->stop;
};

UE::Loop->default_loop->run;
