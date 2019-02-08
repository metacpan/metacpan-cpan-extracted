use strict;
use warnings;

use UV qw(UV_ENOSYS UV_ENOTSOCK);
use UV::Timer;
use UV::Loop qw(UV_LOOP_BLOCK_SIGNAL UV_RUN_DEFAULT SIGPROF);

use Test::More;


# Some options behave differently on Windows
sub CYGWIN () {
    return 1 if $^O eq 'cygwin';
    return '';
}
sub WINLIKE () {
    return 1 if $^O eq 'MSWin32';
    # return 1 if $^O eq 'cygwin';
    return 1 if $^O eq 'msys';
    return '';
}

sub timer_cb {
    my $timer = shift;
    $timer->close();
}

{
    my $loop = UV::Loop->new();
    isa_ok($loop, 'UV::Loop', 'got a new loop');

    if (WINLIKE) {
        is(UV_ENOSYS, $loop->configure(UV_LOOP_BLOCK_SIGNAL, 0), 'Block signal does not work on Windows');
    }
    elsif (CYGWIN) {
        is(UV_ENOTSOCK, $loop->configure(UV_LOOP_BLOCK_SIGNAL, 0), 'Block signal does not work on Windows');
    }
    else {
        is(0, $loop->configure(UV_LOOP_BLOCK_SIGNAL, SIGPROF), 'Configure worked properly');
    }

    my $timer = UV::Timer->new(loop => $loop);
    isa_ok($timer, 'UV::Timer', 'got a new timer for the loop');
    is(0, $timer->start(10, 0, \&timer_cb), 'Timer started');

    is(0, $loop->run(UV_RUN_DEFAULT), 'Loop started');
    is(0, $loop->close(), 'Loop closed');
}

done_testing();
