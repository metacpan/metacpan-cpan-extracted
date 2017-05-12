#!/usr/bin/perl

use strict;
use warnings FATAL => 'all';

use Test::More;
use Time::ETA;
use Time::ETA::MockTime;

sub main {
    {
        my $eta = Time::ETA->new(
            milestones => 2,
        );

        ok(not($eta->is_paused), 'At first the object it not paused');
        eval {
            $eta->resume();
        };
        like($@, qr/The object isn't paused\. Can't resume\. Stopped/, "Can't resume not paused");

        $eta->pause();
        ok($eta->is_paused, 'Paused');

        eval {
            $eta->pause();
        };
        like($@, qr/The object is already paused\. Can't pause paused\. Stopped/, "Can't pause paused");
    }

    {
        Time::ETA::MockTime::set_mock_time(1389200452, 0);
        my $eta = Time::ETA->new(
            milestones => 2,
        );

        my $microseconds = 1_000_000;
        usleep 0.9 * $microseconds;
        $eta->pass_milestone();
        $eta->pause();

        usleep 0.5 * $microseconds;
        $eta->resume();

        ok(Time::ETA->can_spawn($eta->serialize()), 'Eta can be spawned');
        is_deeply($eta->{_start}, [1389200452, 0.5 * $microseconds], 'Start time is correct after resume');
    }

    done_testing();
}

main();
