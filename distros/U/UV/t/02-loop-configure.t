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

    my $err = do {
        local $@;
        eval { $loop->configure(UV_LOOP_BLOCK_SIGNAL, SIGPROF); 1 } ? undef : $@
    };

    if (WINLIKE) {
        isa_ok($err, "UV::Exception::ENOSYS", 'Block signal does not work on Windows');
    }
    elsif (CYGWIN) {
        isa_ok($err, "UV::Exception::ENOTSOCK", 'Block signal does not work on Cygwin');
    }
    else {
        ok(!$err, "Block signal works fine on this OS") or
            diag("Error was $err");
    }

    my $timer = UV::Timer->new(loop => $loop);
    isa_ok($timer, 'UV::Timer', 'got a new timer for the loop');
    $timer->start(10, 0, \&timer_cb);

    is(0, $loop->run(UV_RUN_DEFAULT), 'Loop started');
}

done_testing();
