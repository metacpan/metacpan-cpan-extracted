#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;

use Timer::Wheel;

subtest 'construction' => sub {
    my $tw = new Timer::Wheel;
    isa_ok($tw, 'Timer::Wheel');
    ok($tw->is_empty, 'new wheel is empty');
    is($tw->pending, 0, 'pending is 0');
    is($tw->next, undef, 'next is undef when empty');
    is($tw->sleep_time, undef, 'sleep_time is undef when empty');
};
subtest 'at - basic scheduling' => sub {
    my $tw = new Timer::Wheel;
    my $fired = 0;

    my $id = $tw->at(100, sub { $fired++ });
    ok(defined $id, 'at returns an id');
    is($tw->pending, 1, 'one timer pending');
    ok(!$tw->is_empty, 'not empty');

    # tick before due time — nothing fires
    my $count = $tw->tick(99);
    is($count, 0, 'nothing fires before due time');
    is($fired, 0, 'callback not called');

    # tick at due time
    $count = $tw->tick(100);

    is($count, 1, 'one timer fires');
    is($fired, 1, 'callback called');
    ok($tw->is_empty, 'empty after one-shot fires');

};

subtest 'in - relative scheduling' => sub {
    my $tw = new Timer::Wheel;
    my $fired = 0;
    my $before = time();

    $tw->in(10, sub { $fired++ });

    # The timer should be scheduled ~10 seconds from now
    my $next = $tw->next;
    ok($next >= $before + 10, 'next is at least now+10');
    ok($next <= $before + 11, 'next is at most now+11');

    # Fire it by ticking past the due time
    $tw->tick($next);
    is($fired, 1, 'in callback fired');
};

subtest 'multiple timers fire in order' => sub {
    my $tw = new Timer::Wheel;
    my @order;

    $tw->at(300, sub { push @order, 'c' });
    $tw->at(100, sub { push @order, 'a' });
    $tw->at(200, sub { push @order, 'b' });

    $tw->tick(300);
    is_deeply(\@order, [qw(a b c)], 'timers fire in epoch order');
};

subtest 'tick returns fired count' => sub {
    my $tw = new Timer::Wheel;
    $tw->at(10, sub {});
    $tw->at(20, sub {});
    $tw->at(30, sub {});

    is($tw->tick(15), 1, 'one due at 15');
    is($tw->tick(25), 1, 'one due at 25');
    is($tw->tick(35), 1, 'one due at 35');
    is($tw->tick(40), 0, 'nothing left');
};

subtest 'unique IDs' => sub {
    my $tw = new Timer::Wheel;
    my $id1 = $tw->at(100, sub {});
    my $id2 = $tw->at(200, sub {});
    my $id3 = $tw->at(300, sub {});
    ok($id1 != $id2 && $id2 != $id3, 'IDs are unique');
};

done_testing;
