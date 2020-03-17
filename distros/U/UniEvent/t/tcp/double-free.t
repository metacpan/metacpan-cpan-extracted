use 5.012;
use warnings;
use lib 't/lib'; use MyTest;
use Net::SockAddr;

alarm(10);

my $loop = UE::Loop->default_loop;
my $srv = UE::Tcp->new($loop);
$srv->bind("localhost", 0);
$srv->listen(128);

my $cnt = 1000;
my @d;

my $connected;
$srv->connection_callback(sub {
    my ($self, $cli, $err) = @_;
    fail $err if $err;
    $loop->stop if ++$d[2] == $cnt;
});

my $t = UE::Prepare->new;
$t->start(sub {
    my $cl = UE::Tcp->new($loop);
    $cl->connect_addr($srv->sockaddr, sub {
        my ($handler, $err) = @_;
        fail $err if $err;
        return if ++$d[1] == $cnt;
        $cl->write('GET /gcm/send HTTP/1.0\r\n\r\n', sub { $_[0]->disconnect; });
    });
    $t->stop if ++$d[0] == $cnt;
});

$loop->run;

cmp_deeply(\@d, [$cnt, $cnt, $cnt]);

done_testing();
