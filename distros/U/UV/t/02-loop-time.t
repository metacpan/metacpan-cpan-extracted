use v5.14;
use warnings;

use UV::Loop qw(UV_RUN_NOWAIT);
use UV::Timer ();
use Test::More;

{
    my $start = UV::Loop->default()->now();
    ok($start, "  Start time is $start");
    while (UV::Loop->default->now() - $start < 500) {
        is(0, UV::Loop->default()->run(UV_RUN_NOWAIT), "  run(UV_RUN_NOWAIT): ok for a half-second");
    }
}

{
    my $loop = UV::Loop->new();
    isa_ok($loop, 'UV::Loop', 'got a new loop');
    my $start = $loop->now();
    ok($start, "  Start time is $start");
    while ($loop->now() - $start < 500) {
        is(0, $loop->run(UV_RUN_NOWAIT), "  run(UV_RUN_NOWAIT): ok for a half-second");
    }
}

sub cb {
    my $timer = shift;
    $timer->close(undef);
}

{
    my $loop = UV::Loop->default();
    isa_ok($loop, 'UV::Loop', '->default(): got a new default Loop');
    my $timer = UV::Timer->new();
    isa_ok($timer, 'UV::Timer', 'timer: got a new timer');

    ok(!$loop->alive(), 'loop->alive: not alive yet');
    is($loop->backend_timeout(), 0, 'loop->backend_timeout: still zero');

    $timer->start(1000, 0, \&cb);

    # Don't bother asking if ->backend_timeout is non-zero yet because for
    # libuv-internal reasons it might not be
    #   https://github.com/p5-UV/p5-UV/issues/40
    ok($loop->backend_timeout() <= 1000, 'backend_timeout <= 1 sec');

    is($loop->run(), 0, 'run: ran successfully');

    is($loop->backend_timeout(), 0, "backend_timeout now 0 secs");
}

done_testing();
