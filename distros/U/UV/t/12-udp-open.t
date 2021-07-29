use strict;
use warnings;

use UV::Loop ();
use UV::UDP ();

use Test::More;

use Socket;

use lib "t/lib";
use UVTestHelpers qw(socketpair_inet_dgram);

$^O eq "MSWin32" and
    plan skip_all => "UV::UDP->open is not supported on Windows";

# recv
{
    my ($rd, $wr) = socketpair_inet_dgram();

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
    my ($rd, $wr) = socketpair_inet_dgram();

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
