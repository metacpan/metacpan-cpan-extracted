use strict;
use warnings;

use Test::More;
use IO::Handle;
use UV;
use UV::Loop ();
use UV::Poll qw(UV_WRITABLE);

use lib "t/lib";
use UVTestHelpers qw(pipepair);

# TODO: It's likely this test doesn't actually pass on some platform or other;
# MSWin32 maybe?
# Feel free to 
#   plan skip_all ... if $^O eq "MSWin32"

my ( $rd, $wr ) = pipepair;

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

{
    my $poll = UV::Poll->new(fh => $wr, on_poll => \&poll_cb);
    $poll->start(UV_WRITABLE);

    UV::Loop->default()->run();

    is($poll_cb_called, 1, 'poll cb was invoked');
    is($poll_cb_status, 0, 'poll cb was invoked without error');
    is($poll_cb_events, UV_WRITABLE, 'poll cb was invoked with correct events');
}

done_testing;
