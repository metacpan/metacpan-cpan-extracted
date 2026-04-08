#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;

use Timer::Wheel;

subtest 'pause individual timer' => sub {
    my $tw = new Timer::Wheel;
    my $fired = 0;

    my $id = $tw->at(100, sub { $fired++ });

    is($tw->pause($id), 1, 'pause returns 1');

    $tw->tick(200);
    is($fired, 0, 'paused timer does not fire');
    is($tw->pending, 1, 'still pending (paused, not cancelled)');
};

subtest 'resume individual timer' => sub {
    my $tw = new Timer::Wheel;
    my $fired = 0;

    my $id = $tw->at(100, sub { $fired++ });
    $tw->pause($id);
    $tw->resume($id);

    $tw->tick(200);
    is($fired, 1, 'resumed timer fires');
};

subtest 'pause_all / resume_all' => sub {
    my $tw = new Timer::Wheel;
    my $count = 0;

    $tw->at(100, sub { $count++ });
    $tw->at(200, sub { $count++ });

    $tw->pause_all;
    $tw->tick(300);
    is($count, 0, 'nothing fires when wheel is paused');

    $tw->resume_all;
    $tw->tick(300);
    is($count, 2, 'both fire after resume_all');
};

subtest 'pause non-existent returns 0' => sub {
    my $tw = new Timer::Wheel;
    is($tw->pause(9999), 0, 'pause unknown id returns 0');
    is($tw->resume(9999), 0, 'resume unknown id returns 0');
};

subtest 'pause recurring timer' => sub {
    my $tw = new Timer::Wheel;
    my $count = 0;

    my $id = $tw->every(10, sub { $count++ }, start => 100);

    $tw->tick(100);
    is($count, 1, 'first fire');

    $tw->pause($id);
    $tw->tick(110);
    is($count, 1, 'paused — does not fire');

    $tw->resume($id);
    $tw->tick(120);
    # After resume, epoch 110 fires (catchup) + re-insert at 120 fires too
    is($count, 3, 'resumed — fires catchup and current');
};

done_testing;
