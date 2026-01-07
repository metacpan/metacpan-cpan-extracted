use v5.14;
use warnings;

use UV::Loop ();
use UV::TCP ();

use Test::More;

use Socket;

use lib "t/lib";
use UVTestHelpers qw(socketpair_inet_stream);

$^O eq "MSWin32" and
    plan skip_all => "UV::TCP->open is not supported on Windows";

# read
{
    my ($rd, $wr) = socketpair_inet_stream();

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
    my $ret = $tcp->read_start;
    is($ret, $tcp, '$tcp->read_start returns $tcp');

    $wr->syswrite("data to read");

    UV::Loop->default->run;
    ok($read_cb_called, 'read callback was called');
}

# write
{
    my ($rd, $wr) = socketpair_inet_stream();

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
