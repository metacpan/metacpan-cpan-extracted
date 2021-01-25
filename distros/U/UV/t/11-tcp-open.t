use strict;
use warnings;

use UV::Loop ();
use UV::TCP ();

use Test::More;

use IO::Socket::INET;
use Socket;

# TODO: This test might not work on MSWin32. We might need to find a different
#   implementation, or just skip it?

sub socketpair_inet
{
    my ($rd, $wr);

    # Maybe socketpair(2) can do it?
    ($rd, $wr) = IO::Socket->socketpair(AF_INET, SOCK_STREAM, 0)
        and return ($rd, $wr);

    # If not, go the long way round
    my $listen = IO::Socket::INET->new(
        LocalHost => "127.0.0.1",
        LocalPort => 0,
        Listen    => 1,
    ) or die "Cannot listen - $@";

    $rd = IO::Socket::INET->new(
        PeerHost => $listen->sockhost,
        PeerPort => $listen->sockport,
    ) or die "Cannot connect - $@";

    $wr = $listen->accept or die "Cannot accept - $!";

    return ($rd, $wr);
}

# read
{
    my ($rd, $wr) = socketpair_inet();

    my $tcp = UV::TCP->new;
    isa_ok($tcp, 'UV::TCP');

    $tcp->open($rd);

    my $read_cb_called;
    $tcp->on(read => sub {
        my ($self, $status, $buf) = @_;
        $read_cb_called++;

        is($buf, "data to read", 'data was read from tcp socket');

        $self->close;
    });
    $tcp->read_start;

    $wr->syswrite("data to read");

    UV::Loop->default->run;
    ok($read_cb_called, 'read callback was called');
}

# write
{
    my ($rd, $wr) = socketpair_inet();

    my $tcp = UV::TCP->new;

    $tcp->open($wr);

    my $write_cb_called;
    my $req = $tcp->write("data to write", sub { $write_cb_called++ } );

    UV::Loop->default->run;
    ok($write_cb_called, 'write callback was called');

    $rd->sysread(my $buf, 8192);
    is($buf, "data to write", 'data was written to tcp socket');

    # both libuv and perl want to close(2) this filehandle. Perl will warn if
    # it gets  EBADF
    { no warnings; undef $wr; }
}

done_testing();
