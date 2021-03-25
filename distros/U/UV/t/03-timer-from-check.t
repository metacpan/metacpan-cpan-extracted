use strict;
use warnings;

use Test::More;
use UV;
use UV::Loop;
use UV::Check;
use UV::Prepare;
use UV::Idle;
use UV::Timer;

my $prepare_handle;
my $check_handle;
my $timer_handle;

my $prepare_cb_called = 0;
my $check_cb_called = 0;
my $timer_cb_called = 0;

sub prepare_cb {
    my $handle = shift;
    $prepare_handle->stop();

    is(0, $prepare_cb_called, 'prepare cb not yet called');
    is(1, $check_cb_called, 'check cb called once');
    is(0, $timer_cb_called, 'timer cb not yet called');
    $prepare_cb_called++;
}

sub timer_cb {
    my $handle = shift;
    $timer_handle->stop();

    is(1, $prepare_cb_called, 'prepare cb called once');
    is(1, $check_cb_called, 'check cb called once');
    is(0, $timer_cb_called, 'timer cb not yet called');
    $timer_cb_called++;
}

sub check_cb {
    my $handle = shift;
    $check_handle->stop();
    $timer_handle->stop();

    $timer_handle->start(50, 0, \&timer_cb);
    $prepare_handle->start(\&prepare_cb);

    is(0, $prepare_cb_called, 'prepare cb not yet called');
    is(0, $check_cb_called, 'check cb not yet called');
    is(0, $timer_cb_called, 'timer cb not yet called');
    $check_cb_called++;
}

{
    $prepare_handle = UV::Prepare->new();
    isa_ok($prepare_handle, 'UV::Prepare', 'Got a new prepare handle');
    $check_handle = UV::Check->new();
    isa_ok($check_handle, 'UV::Check', 'Got a new check handle');
    $timer_handle = UV::Timer->new();
    isa_ok($timer_handle, 'UV::Timer', 'Got a new timer handle');

    $check_handle->start(\&check_cb);
    $timer_handle->start(50, 0, \&timer_cb);

    is(0, UV::default_loop()->run(UV::Loop::UV_RUN_DEFAULT), 'loop started');

    is(1, $prepare_cb_called, 'prepare cb called once');
    is(1, $check_cb_called, 'check cb called once');
    is(1, $timer_cb_called, 'timer cb called once');

    $prepare_handle->close(sub {});
    $check_handle->close(sub {});
    $timer_handle->close(sub {});

    is(0, UV::default_loop()->run(UV::Loop::UV_RUN_ONCE), 'loop run once');
}

done_testing();
