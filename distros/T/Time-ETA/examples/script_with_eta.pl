#!/usr/bin/perl

use strict;
use warnings;

use lib::abs '../lib';
use Time::ETA;

use Time::HiRes qw( usleep);

sub do_work {
    print "Working...\n";
    sleep 1;
};

my $count = 6;

my $eta = Time::ETA->new(
    milestones => $count,
);

foreach (1..$count) {
    if ($eta->can_calculate_eta()) {
        print
            "Completed "
            . $eta->get_completed_percent()
            . "%."
            ." Will end in "
            .  $eta->get_remaining_seconds()
            . " seconds\n";

    } else {
        print "Don't know how long the process will take\n";
    }
    do_work();
    $eta->pass_milestone();
}

print "Finished!\n";
