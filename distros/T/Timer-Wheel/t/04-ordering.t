#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;

use Timer::Wheel;

subtest 'strict ordering with same-granularity epochs' => sub {
    my $tw = new Timer::Wheel;
    my @order;

    for my $i (1..20) {
        $tw->at($i, sub { push @order, $i });
    }

    $tw->tick(20);
    is_deeply(\@order, [1..20], 'fires 1-20 in order');
};

subtest 'reverse insertion order' => sub {
    my $tw = new Timer::Wheel;
    my @order;

    for my $i (reverse 1..10) {
        $tw->at($i, sub { push @order, $i });
    }

    $tw->tick(10);
    is_deeply(\@order, [1..10], 'fires in epoch order despite reverse insertion');
};

subtest 'same epoch - all fire' => sub {
    my $tw = new Timer::Wheel;
    my $count = 0;

    $tw->at(100, sub { $count++ }) for 1..5;

    my $fired = $tw->tick(100);
    is($fired, 5, 'all 5 same-epoch timers fire');
    is($count, 5, 'callbacks all called');
};

subtest 'fractional epochs ordered correctly' => sub {
    my $tw = new Timer::Wheel;
    my @order;

    $tw->at(1.3, sub { push @order, 'c' });
    $tw->at(1.1, sub { push @order, 'a' });
    $tw->at(1.2, sub { push @order, 'b' });

    $tw->tick(2);
    is_deeply(\@order, [qw(a b c)], 'fractional epochs in correct order');
};

done_testing;
