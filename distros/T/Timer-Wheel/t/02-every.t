#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;

use Timer::Wheel;

subtest 'every - recurring timer' => sub {
    my $tw = new Timer::Wheel;
    my $count = 0;

    $tw->every(10, sub { $count++ }, start => 100);

    $tw->tick(100);
    is($count, 1, 'fires at start');

    $tw->tick(109);
    is($count, 1, 'does not fire before next interval');

    $tw->tick(110);
    is($count, 2, 'fires at start+interval');

    $tw->tick(120);
    is($count, 3, 'fires again at start+2*interval');
};

subtest 'every - drift prevention' => sub {
    my $tw = new Timer::Wheel;
    my $count = 0;

    # Start at 100, interval 10
    $tw->every(10, sub { $count++ }, start => 100);

    # Tick late at 115 — fires for epoch 100 AND 110 (both due), re-inserts at 120
    $tw->tick(115);
    is($count, 2, 'fires twice for both due epochs');

    # Next should be at 120 (no drift from late tick)
    is($tw->next, 120, 'next fire at 120 (no drift)');

    $tw->tick(120);
    is($count, 3, 'fires at 120');
};

subtest 'every - fire multiple catchups in one tick' => sub {
    my $tw = new Timer::Wheel;
    my $count = 0;

    $tw->every(5, sub { $count++ }, start => 100);

    # tick(120) fires: 100, 105, 110, 115, 120 — all in one call
    my $fired = $tw->tick(120);
    is($fired, 5, 'fires 5 catchup intervals in one tick');
    is($count, 5, 'callback called 5 times');
    is($tw->next, 125, 'next at 125');
};

subtest 'every - cancel stops recurrence' => sub {
    my $tw = new Timer::Wheel;
    my $count = 0;

    my $id = $tw->every(10, sub { $count++ }, start => 100);

    $tw->tick(100);
    is($count, 1, 'fires once');

    $tw->cancel($id);
    $tw->tick(110);
    is($count, 1, 'does not fire after cancel');
};

done_testing;
