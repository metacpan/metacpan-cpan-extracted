use v5.14;
use warnings;

use Test::More;

use UV ();
use UV::Loop qw(UV_RUN_ONCE UV_RUN_DEFAULT);
use UV::Timer ();

my $once_cb_called = 0;
my $once_close_cb_called = 0;
my $repeat_cb_called = 0;
my $repeat_close_cb_called = 0;
my $order_cb_called = 0;
my $start_time;
my $tiny_timer;
my $huge_timer1;
my $huge_timer2;

sub once_close_cb {
    my $handle = shift;
    ok($handle, 'Got a handle in the once_close_cb');
    ok(!$handle->active(), 'handle is not active');
    $once_close_cb_called++;
}


sub once_cb {
    my $handle = shift;
    ok($handle, 'Got a handle in the once_cb');
    ok(!$handle->active(), 'handle is not active');

    $once_cb_called++;

    $handle->close(\&once_close_cb);

    # Just call this randomly for the code coverage.
    UV::Loop->default()->update_time();
}


sub repeat_close_cb {
    my $handle = shift;
    ok($handle, 'Got a handle in the repeat_once_cb');
    $repeat_close_cb_called++;
}


sub repeat_cb {
    my $handle = shift;
    ok($handle, 'Got a handle in the repeat_cb');
    ok($handle->active(), 'handle is active');

    $repeat_cb_called++;

    if ($repeat_cb_called == 5) {
        $handle->close(\&repeat_close_cb);
    }
}


sub never_cb {
    my $handle = shift;
    fail("never_cb should never be called");
    done_testing();
    exit(1);
}

#timer
{
    my $start_time = UV::Loop->default()->now();
    ok(0 < $start_time, 'Start time is positive');

    # Let 10 timers time out in 500 ms total.
    my @once_timers;
    for my $i (0 .. 9) {
        my $once = UV::Timer->new();
        isa_ok($once, 'UV::Timer', "Got a timer to add to the array");
        push @once_timers, $once;
        $once->start($i*50, 0, \&once_cb);
    }

    # The 11th timer is a repeating timer that runs 4 times
    my $repeat = UV::Timer->new();
    isa_ok($repeat, 'UV::Timer', "Got a repeat timer");
    $repeat->start(100, 100, \&repeat_cb);

    # The 12th timer should not do anything
    my $never = UV::Timer->new();
    isa_ok($never, 'UV::Timer', "Got a never timer");
    $never->start(100, 100, \&never_cb);
    $never->stop();
    $never->close(undef);

    UV::Loop->default()->run();

    is($once_cb_called, 10, 'Once_cb called 10 times');
    is($once_close_cb_called, 10, 'Once_close_cb called 10 times');
    is($repeat_cb_called, 5, 'repeat_cb called 5 times');
    is($repeat_close_cb_called, 1, 'repeat_close_cb called once');
    ok(500 <= UV::Loop->default()->now() - $start_time, 'finished in < 500 ms');
}

# timer start twice
{
    $once_cb_called = 0;
    my $once = UV::Timer->new();
    isa_ok($once, 'UV::Timer', 'got a new timer');
    $once->start(86400 * 1000, 0, \&never_cb);
    my $ret = $once->start(10, 0, \&once_cb);
    is($ret, $once, '$timer->start returns $timer');

    is(0, UV::Loop->default->run(), 'default loop run');
    is($once_cb_called, 1, 'once cb called once');
}

# timer_init
{
    my $handle = UV::Timer->new();
    isa_ok($handle, 'UV::Timer', 'Got a new timer');
    $handle->repeat();
    ok(!$handle->active(), 'handle is not active');
}

sub order_cb_a {
    my $handle = shift;
    ok($order_cb_called++ == int($handle->data));
}


sub order_cb_b {
    my $handle = shift;
    ok($order_cb_called++ == int($handle->data));
}

# time order
{
    my $handle_a = UV::Timer->new();
    isa_ok($handle_a, 'UV::Timer', 'handle_a created');
    my $handle_b = UV::Timer->new();
    isa_ok($handle_b, 'UV::Timer', 'handle_b created');

    my $first = 0;
    my $second = 1;

    # Test for starting handle_a then handle_b
    $handle_a->data($first);
    $handle_a->start(0, 0, \&order_cb_a);

    $handle_b->data($second);
    $handle_b->start(0, 0, \&order_cb_b);

    is(0, UV::Loop->default()->run(), 'default loop run');

    is($order_cb_called, 2, 'got the right number of CBs called');

    $handle_a->stop();
    $handle_b->stop();

    # Test for starting handle_b then handle_a
    $order_cb_called = 0;
    $handle_b->data($first);
    $handle_b->start(0, 0, \&order_cb_b);

    $handle_a->data($second);
    $handle_a->start(0, 0, \&order_cb_a);

    is(0, UV::Loop->default()->run(), 'default loop run');

    is($order_cb_called, 2, 'Got the right number of CBs called');
}


sub tiny_timer_cb {
    my $handle = shift;

    is($handle, $tiny_timer, 'Got the right tiny timer');

    $tiny_timer->close(undef);
    $huge_timer1->close(undef);
    $huge_timer2->close(undef);
}

# timer_huge_timeout
{
    $tiny_timer = UV::Timer->new();
    isa_ok($tiny_timer, 'UV::Timer', 'tiny_timer new');
    $huge_timer1 = UV::Timer->new();
    isa_ok($huge_timer1, 'UV::Timer', 'huge_timer1 new');
    $huge_timer2 = UV::Timer->new();
    isa_ok($huge_timer2, 'UV::Timer', 'huge_timer2 new');

    $tiny_timer->start(1, 0, \&tiny_timer_cb);
    $huge_timer1->start(4294967295, 0, \&tiny_timer_cb);
    $huge_timer2->start(-1, 0, \&tiny_timer_cb);
    is(0, UV::Loop->default()->run(), 'default loop run');
}

my $ncalls = 0;
sub huge_repeat_cb {
    my $handle = shift;

    if ($ncalls == 0) {
        is($handle, $huge_timer1, 'Got the huge_timer1 in huge_repeat_cb');
    }
    else {
        is($handle, $tiny_timer, 'Got the tiny_timer in huge_repeat_cb');
    }

    if (++$ncalls == 10) {
        $tiny_timer->close(undef);
        $huge_timer1->close(undef);
    }
}

# timer_huge_repeat
{
    $tiny_timer = UV::Timer->new();
    $huge_timer1 = UV::Timer->new();
    isa_ok($tiny_timer, 'UV::Timer', 'tiny_timer new');
    isa_ok($huge_timer1, 'UV::Timer', 'huge_timer1 new');
    $tiny_timer->start(2, 2, \&huge_repeat_cb);
    $huge_timer1->start(1, -1, \&huge_repeat_cb);
    is(0, UV::Loop->default()->run(), 'default loop run');
}


my $timer_run_once_timer_cb_called;


sub timer_run_once_timer_cb {
    $timer_run_once_timer_cb_called++;
}


# timer_run_once
{
    my $timer_handle = UV::Timer->new();
    isa_ok($timer_handle, 'UV::Timer', 'timer_handle new');
    $timer_handle->start(0, 0, \&timer_run_once_timer_cb);
    is(0, UV::Loop->default()->run(UV_RUN_ONCE), 'default loop run once');
    is(1, $timer_run_once_timer_cb_called, 'callback called once');

    $timer_handle->start(1, 0, \&timer_run_once_timer_cb);
    is(0, UV::Loop->default()->run(UV_RUN_ONCE), 'default loop run once');
    is(2, $timer_run_once_timer_cb_called, 'callback called twice');

    $timer_handle->close(undef);
    is(0, UV::Loop->default()->run(UV_RUN_ONCE), 'default loop run once');
}


# timer_early_check
{
    my $timeout_ms = 10;

    my $timer_early_check_expected_time = UV::Loop->default()->now() + $timeout_ms;

    my $timer_handle = UV::Timer->new();
    isa_ok($timer_handle, 'UV::Timer', 'got a new timer');
    $timer_handle->start($timeout_ms, 0,
        sub {
            my $hrtime = UV::hrtime() / 1000000;
            cmp_ok($hrtime, '>=', $timer_early_check_expected_time, 'hires time >= expected check time');
        }
    );

    is(UV::Loop->default()->run(UV_RUN_DEFAULT), 0, 'loop run before handle close');

    $timer_handle->close(undef);
    is(UV::Loop->default()->run(UV_RUN_DEFAULT), 0, 'loop run after handle close');
}

done_testing();
