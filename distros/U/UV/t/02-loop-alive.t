use v5.14;
use warnings;

use Test::More;
use UV::Loop qw(UV_RUN_DEFAULT);
use UV::Timer ();

{
    my $l = UV::Loop->default(); # singleton
    ok(!$l->alive(), 'Default loop is not alive');
    my $l2 = UV::Loop->default(); # singleton
    is($l, $l2, 'Got the same default loop');
}

{
    my $loop = UV::Loop->default_loop();
    ok(!$loop->alive(), 'default loop is not alive');
    $loop->run(UV_RUN_DEFAULT);
}

{
    my $loop = UV::Loop->new(); # not a singleton
    ok(!$loop->alive(), 'Non-default loop is not alive');
}

sub timer_cb {
    my $timer = shift;
    isa_ok($timer, 'UV::Timer', 'got a timer');
}

{
    my $loop = UV::Loop->default();
    my $timer = UV::Timer->new(
        loop => $loop,
        on_timer => \&timer_cb,
    );
    isa_ok($timer, 'UV::Timer', 'got a timer');
    $timer->start(0,0);
    ok($loop->alive(), 'A loop with a handle is alive');
    is($loop->run(UV_RUN_DEFAULT), 0, 'loop ran');

    ok(!$loop->alive(), 'loop is no longer alive');
}

done_testing();
