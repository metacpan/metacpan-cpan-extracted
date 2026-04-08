#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;

use Timer::Wheel;

subtest 'drain fires everything' => sub {
    my $tw = new Timer::Wheel;
    my @fired;

    $tw->at(999999, sub { push @fired, 'far_future' });
    $tw->at(1,      sub { push @fired, 'past' });
    $tw->at(500000, sub { push @fired, 'mid' });

    my $count = $tw->drain;
    is($count, 3, 'drain fires all 3');
    is_deeply(\@fired, [qw(past mid far_future)], 'drain fires in order');
};

subtest 'drain recurring fires once then removes' => sub {
    my $tw = new Timer::Wheel;
    my $count = 0;

    $tw->every(10, sub { $count++ }, start => 100);

    my $fired = $tw->drain;
    is($fired, 1, 'drain fires recurring once');
    is($count, 1, 'callback called once');
    is($tw->pending, 0, 'recurring timer removed after drain');
    ok($tw->is_empty, 'wheel empty after drain');
};

subtest 'drain on empty wheel' => sub {
    my $tw = new Timer::Wheel;
    is($tw->drain, 0, 'drain on empty returns 0');
};

done_testing;
