use strict;
use warnings;

use Test::More;
use UV;
use UV::Timer ();

my $close_cb_called = 0;
my $repeat_1_cb_called = 0;
my $repeat_2_cb_called = 0;
my $repeat_2_cb_allowed = 0;

my $dummy;      # timer
my $repeat_1;   # timer
my $repeat_2;   # timer

my $start_time;

sub close_cb {
    my $handle = shift;
    ok($handle, 'Got a handle in the close callback');
    $close_cb_called++;
}

sub repeat_1_cb {
    my $handle = shift;
    is($handle, $repeat_1, 'Got the right handle in the repeat_1 cb');

    my $ms = UV::default_loop()->now() - $start_time;
    # diag("repeat_1_cb called after $ms ms");

    is($handle->repeat(), 50, 'Got the right timer repeat value');
    $repeat_1_cb_called++;

    $repeat_2->again();

    if ($repeat_1_cb_called == 10) {
        $handle->close(\&close_cb);
        # we're not calling ->again on repeat_2 anymore. so after this,
        # timer_2_cb is expected
        $repeat_2_cb_allowed = 1;
    }
}

sub repeat_2_cb {
    my $handle = shift;
    is($handle, $repeat_2, 'Got the right handle in repeat 2 cb');
    ok($repeat_2_cb_allowed, 'repeat 2 cb allowed');

    my $ms = UV::default_loop()->now() - $start_time;
    #diag("repeat_2_cb called after $ms ms");
    $repeat_2_cb_called++;

    if (0 == $repeat_2->repeat()) {
        ok(!$handle->active(), 'not active');
        $handle->close(\&close_cb);
        return;
    }
    is(100, $repeat_2->repeat(), 'Repeat 2 repeat correct');
    $repeat_2->repeat(0);
}

{
    $start_time = UV::default_loop()->now();
    ok(0 < $start_time, "got a positive start time");

    # Verify that it is not possible to uv_timer_again a never-started timer
    $dummy = UV::Timer->new();
    isa_ok($dummy, 'UV::Timer', 'Got a new timer');
    my $err = do { local $@; eval { $dummy->again(); 1 } ? undef : $@ };
    isa_ok($err, "UV::Exception::EINVAL", '->again failed EINVAL as expected');
    undef $dummy;

    # Start timer repeat_1
    $repeat_1 = UV::Timer->new();
    isa_ok($repeat_1, 'UV::Timer', 'repeat_1 timer new');
    $repeat_1->start(50, 0, \&repeat_1_cb);
    is($repeat_1->repeat(), 0, 'repeat_1 has the right repeat');

    # Actually make repeat_1 repeating
    $repeat_1->repeat(50);
    is($repeat_1->repeat(), 50, 'got the right repeat value');

    # Start another repeating timer. It'll be again()ed by the repeat_1 so
    # it should not time out until repeat_1 stops
    $repeat_2 = UV::Timer->new();
    isa_ok($repeat_2, 'UV::Timer', 'repeat_2 timer new');
    $repeat_2->start(100, 100, \&repeat_2_cb);
    is($repeat_2->repeat(), 100, 'Got the right repeat value for repeat_2');

    UV::default_loop()->run(UV::Loop::UV_RUN_DEFAULT);

    is($repeat_1_cb_called, 10, 'repeat 1 called 10 times');
    is($repeat_2_cb_called, 2, 'repeat 2 called 2 times');
    is($close_cb_called, 2, 'close cb called 2 times');

    my $ms = UV::default_loop()->now() - $start_time;
    diag("Test took $ms ms (expected ~700ms)");
}

done_testing();
