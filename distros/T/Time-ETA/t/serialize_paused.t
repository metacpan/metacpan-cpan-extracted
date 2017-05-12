#!/usr/bin/perl

use strict;
use warnings FATAL => 'all';
use Test::More;

BEGIN {
    if (!eval q{ use Test::Differences; 1 }) {
        *eq_or_diff = \&is_deeply;
    }
}

use Time::ETA;
use Time::ETA::MockTime;

my $true = 1;
my $false = '';

sub main {
    Time::ETA::MockTime::set_mock_time(1389200452, 619014);

    my $eta = Time::ETA->new(
        milestones => 3,
    );

    sleep 1;
    $eta->pause();

    my $data1 =
"---
_elapsed: 1
_end: ~
_is_paused: 1
_milestone_pass: ~
_milestones: 3
_passed_milestones: 0
_start: ~
_version: 3
";

    eq_or_diff(
        $eta->serialize(),
        $data1,
        'serialize() in pause stage return corect data before any milestone pass',
    );
    my $respawned1 = Time::ETA->spawn($eta->serialize());
    eq_or_diff(
        $respawned1->serialize(),
        $data1,
        'Respawned object also serializes correct',
    );
    $eta->resume();
    $eta->pass_milestone();

    sleep 1;
    my $data2 =
"---
_elapsed: 0
_end: ~
_is_paused: ''
_milestone_pass:
  - 1389200453
  - 619014
_milestones: 3
_passed_milestones: 1
_start:
  - 1389200452
  - 619014
_version: 3
";
    eq_or_diff(
        $eta->serialize(),
        $data2,
        'serialize() in working stage return corect after first milestone pass',
    );
    my $respawned2 = Time::ETA->spawn($eta->serialize());
    eq_or_diff(
        $respawned2->serialize(),
        $data2,
        'Respawned object also serializes correct',
    );

    done_testing();

}

main();
__END__
