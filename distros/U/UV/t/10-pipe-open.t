use strict;
use warnings;

use UV::Loop ();
use UV::Pipe ();

use Test::More;

# TODO: This test might not work on MSWin32. We might need to find a different
#   implementation, or just skip it?

# read
{
    pipe my ($rd, $wr) or die "Cannot pipe - $!";

    my $pipe = UV::Pipe->new;
    isa_ok($pipe, 'UV::Pipe');

    $pipe->open($rd);

    my $read_cb_called;
    $pipe->on(read => sub {
        my ($self, $status, $buf) = @_;
        $read_cb_called++;

        is($buf, "data to read", 'data was read from pipe');

        $self->close;
    });
    $pipe->read_start;

    $wr->syswrite("data to read");

    UV::Loop->default->run;
    ok($read_cb_called, 'read callback was called');
}

# write
{
    pipe my ($rd, $wr) or die "Cannot pipe - $!";

    my $pipe = UV::Pipe->new;

    $pipe->open($wr);

    my $write_cb_called;
    my $req = $pipe->write("data to write", sub { $write_cb_called++ } );

    UV::Loop->default->run;
    ok($write_cb_called, 'write callback was called');

    $rd->sysread(my $buf, 8192);
    is($buf, "data to write", 'data was written to pipe');

    # both libuv and perl want to close(2) this filehandle. Perl will warn if
    # it gets EBADF
    { no warnings; undef $wr; }
}

done_testing();
