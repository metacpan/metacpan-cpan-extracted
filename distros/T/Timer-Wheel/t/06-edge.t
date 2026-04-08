#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;

use Timer::Wheel;

subtest 'tick on empty wheel' => sub {
    my $tw = new Timer::Wheel;
    is($tw->tick(100), 0, 'tick on empty returns 0');
};

subtest 'past-time timers fire immediately' => sub {
    my $tw = new Timer::Wheel;
    my $fired = 0;

    $tw->at(50, sub { $fired++ });

    # tick at time after the scheduled epoch
    $tw->tick(100);
    is($fired, 1, 'past timer fires on tick');
};

subtest 'zero delay in' => sub {
    my $tw = new Timer::Wheel;
    my $fired = 0;
    my $before = time();

    $tw->in(0, sub { $fired++ });
    my $next = $tw->next;

    # Should be scheduled at ~now
    ok($next >= $before && $next <= $before + 1, 'zero delay schedules at ~now');
    $tw->tick($next);
    is($fired, 1, 'zero-delay fires on tick');
};

subtest 'large number of timers' => sub {
    my $tw = new Timer::Wheel;
    my $count = 0;

    for my $i (1..1000) {
        $tw->at($i, sub { $count++ });
    }

    is($tw->pending, 1000, '1000 pending');
    $tw->tick(1000);
    is($count, 1000, 'all 1000 fired');
    ok($tw->is_empty, 'empty after all fired');
};

subtest 'next and sleep_time' => sub {
    my $tw = new Timer::Wheel;
    is($tw->next, undef, 'next undef on empty');
    is($tw->sleep_time, undef, 'sleep_time undef on empty');

    $tw->at(time() + 100, sub {});
    ok(defined $tw->next, 'next defined after adding timer');
    my $st = $tw->sleep_time;
    ok($st > 98 && $st <= 101, 'sleep_time roughly correct');
};

done_testing;
