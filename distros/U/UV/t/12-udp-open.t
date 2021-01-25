use strict;
use warnings;

use UV::Loop ();
use UV::UDP ();

use Test::More;

use IO::Socket::INET;
use Socket;

# TODO: This test might not work on MSWin32. We might need to find a different
#   implementation, or just skip it?

sub socketpair_inet
{
    my ($rd, $wr);

    # Maybe socketpair(2) can do it?
    ($rd, $wr) = IO::Socket->socketpair(AF_INET, SOCK_DGRAM, 0)
        and return ($rd, $wr);

    # If not, go the long way round
    $rd = IO::Socket::INET->new(
        LocalHost => "127.0.0.1",
        LocalPort => 0,
        Proto     => "udp",
    ) or die "Cannot socket - $@";

    $wr = IO::Socket::INET->new(
        PeerHost => $rd->sockhost,
        PeerPort => $rd->sockport,
        Proto    => "udp",
    ) or die "Cannot socket/connect - $@";

    $rd->connect($wr->sockport, inet_aton($wr->sockhost)) or die "Cannot connect - $!";

    return ($rd, $wr);
}

# recv
{
    my ($rd, $wr) = socketpair_inet();

    my $udp = UV::UDP->new;
    isa_ok($udp, 'UV::UDP');

    $udp->open($rd);

    my $recv_cb_called;
    $udp->on(recv => sub {
        my ($self, $status, $buf, $addr) = @_;
        $recv_cb_called++;

        is($buf, "data to recv", 'data was recved from udp socket');
        is($addr, $wr->sockname, 'addr gives peer sockaddr');

        $self->close;
    });
    $udp->recv_start;

    $wr->send("data to recv");

    UV::Loop->default->run;
    ok($recv_cb_called, 'recv callback was called');
}

# send
{
    my ($rd, $wr) = socketpair_inet();

    my $udp = UV::UDP->new;

    $udp->open($wr);

    my $send_cb_called;
    my $req = $udp->send("data to send", sub { $send_cb_called++ } );

    UV::Loop->default->run;
    ok($send_cb_called, 'send callback was called');

    $rd->recv(my $buf, 8192);
    is($buf, "data to send", 'data was sent to udp socket');

    $udp->try_send("more data");

    $rd->recv($buf, 8192);
    is($buf, "more data", 'data was sent to udp socket by try_send');

    # both libuv and perl want to close(2) this filehandle. Perl will warn if
    # it gets  EBADF
    { no warnings; undef $wr; }
}

done_testing();
