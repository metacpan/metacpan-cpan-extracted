#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;

use Timer::Wheel;

subtest 'cancel by id' => sub {
    my $tw = new Timer::Wheel;
    my $fired = 0;

    my $id = $tw->at(100, sub { $fired++ });
    is($tw->pending, 1, 'one pending');

    my $ok = $tw->cancel($id);
    is($ok, 1, 'cancel returns 1');
    is($tw->pending, 0, 'zero pending after cancel');

    $tw->tick(200);
    is($fired, 0, 'callback never fires');
};

subtest 'cancel non-existent id' => sub {
    my $tw = new Timer::Wheel;
    is($tw->cancel(9999), 0, 'cancel unknown id returns 0');
};

subtest 'cancel one of many' => sub {
    my $tw = new Timer::Wheel;
    my @fired;

    my $id1 = $tw->at(100, sub { push @fired, 'a' });
    my $id2 = $tw->at(200, sub { push @fired, 'b' });
    my $id3 = $tw->at(300, sub { push @fired, 'c' });

    $tw->cancel($id2);
    $tw->tick(400);

    is_deeply(\@fired, [qw(a c)], 'only cancelled timer skipped');
};

subtest 'cancel_all' => sub {
    my $tw = new Timer::Wheel;
    my $fired = 0;

    $tw->at(100, sub { $fired++ });
    $tw->at(200, sub { $fired++ });
    $tw->at(300, sub { $fired++ });

    my $count = $tw->cancel_all;
    is($count, 3, 'cancel_all returns count');
    is($tw->pending, 0, 'all cancelled');

    $tw->tick(400);
    is($fired, 0, 'nothing fires');
};

done_testing;
