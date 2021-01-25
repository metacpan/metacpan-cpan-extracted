use strict;
use warnings;

use Test::More;
use IO::Handle;
use UV;
use UV::Loop ();
use UV::Poll qw(UV_READABLE);

# TODO: It's likely this test doesn't actually pass on some platform or other;
# MSWin32 maybe?
# Feel free to 
#   plan skip_all ... if $^O eq "MSWin32"

pipe my ( $rd, $wr ) or die "Unable to pipe() - $!";

my $poll_cb_called = 0;
my ( $poll_cb_status, $poll_cb_events );

sub poll_cb
{
    my $self = shift;
    ( $poll_cb_status, $poll_cb_events ) = @_;
    $poll_cb_called++;
    $self->stop();
    $self->close();
}

# make the pipe readable
$wr->autoflush(1);
$wr->syswrite("Hello\n");

{
    my $poll = UV::Poll->new(fh => $rd, on_poll => \&poll_cb);
    $poll->start(UV_READABLE);

    UV::Loop->default()->run();

    is($poll_cb_called, 1, 'poll cb was invoked');
    is($poll_cb_status, 0, 'poll cb was invoked without error');
    is($poll_cb_events, UV_READABLE, 'poll cb was invoked with correct events');
}

# Unit test the error message throwing logic
{
    # Invoke the underlying ->_new method so we can fabricate an error
    my $FILE = $0;
    my $LINE = __LINE__+1;
    my $err = do { local $@; eval { UV::Poll->_new(UV::Loop->default, -1, 0); 1 } ? undef : $@ };
    isa_ok($err, 'UV::Exception::EBADF');
    isa_ok($err, 'UV::Exception');
    like($err, qr/^Couldn't initialise poll handle \(-\d+\): .* at \Q$FILE\E line \Q$LINE\E.\n/,
        'Stringified error message');
    is($err->code, UV::UV_EBADF, 'Numerical error code');
}

done_testing;
