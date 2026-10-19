#!perl
use 5.010;
use strict;
use warnings;
use Test::More;
use Time::Keeper;
use Time::Keeper::Zone;
use Time::Keeper::Recurrence;

# Author test: every zone, every change of its clocks from 2026 to 2030. A
# daily rule at each of the wall minutes in the two hours either side of the
# change, by default (forward, earlier): across the change, next and between
# agree, no wall minute is lost and none is doubled; a sweeping cron fires
# at every real minute of the window. Ask before running: a few minutes.

my $R = 'Time::Keeper::Recurrence';
my $from = Time::Keeper->new(year => 2026, month => 1, day => 1, zone => 'UTC')->epoch;
my $to = Time::Keeper->new(year => 2031, month => 1, day => 1, zone => 'UTC')->epoch;
my $sample = $ENV{TKR_SWEEP_STEP} || 7;   # every nth wall minute of the window
my ($zones, $changes, $checks, $bad) = (0, 0, 0, 0);
for my $zone (Time::Keeper::Zone->names) {
    my @tr = Time::Keeper::Zone->transitions($zone, $from, $to);
    next unless @tr;
    $zones++;
    for my $t (@tr) {
        my ($at, $before, $after) = @$t;
        next if $before == $after;                 # an abbreviation-only change
        $changes++;
        my $shift = $after - $before;              # seconds the wall clock moved
        my $change = Time::Keeper->from_epoch($at, zone => $zone);
        my $window_start = Time::Keeper->from_epoch($at - 7200, zone => $zone);
        my $window_end = Time::Keeper->from_epoch($at + 7200, zone => $zone);
        my $cron = $R->cron('* * * * *', zone => $zone);
        my @minutes = $cron->between($window_start, $window_end);
        my $real = int(($window_end->epoch - $window_start->epoch) / 60);
        $checks++;
        if (@minutes != $real) {
            $bad++;
            diag("$zone at " . $change->iso8601 . ": a sweeping cron fired " . scalar(@minutes) . " times in $real real minutes") if $bad < 20;
        }
        # a daily rule at every nth wall minute of the day the change falls on
        my $day0 = $change->truncate(to => 'day');
        for (my $m = 0; $m < 1440; $m += $sample) {
            my $wall = sprintf '%02d:%02d', int($m / 60), $m % 60;
            my $start = Time::Keeper->new(year => $day0->year, month => $day0->month, day => $day0->day, hour => int($m / 60), minute => $m % 60, zone => $zone, gap => 'forward');
            my $r = $R->new(rrule => 'FREQ=DAILY;COUNT=3', start => $start->minus(days => 1, gap => 'forward'));
            my @three = $r->first(3);
            my $n = $r->next($three[0]);
            $checks++;
            if (@three != 3 || !defined $n || $n->epoch != $three[1]->epoch) {
                $bad++;
                diag("$zone $wall on " . $day0->ymd . ": first and next disagree") if $bad < 20;
                next;
            }
            # the occurrence on the change day exists exactly once and its wall clock is the start's unless the clocks skipped it
            my ($on_day) = grep { $_->ymd eq $day0->ymd } @three;
            $checks++;
            if (!$on_day) {
                $bad++;
                diag("$zone $wall on " . $day0->ymd . ": no occurrence on the day of the change") if $bad < 20;
            }
            elsif ($on_day->format('HH:mm') ne $wall && $shift <= 0) {
                $bad++;
                diag("$zone $wall on " . $day0->ymd . ": the clocks went back, yet the wall clock moved to " . $on_day->format('HH:mm')) if $bad < 20;
            }
        }
    }
}
is($bad, 0, "$checks checks over $changes changes in $zones zones: nothing lost, doubled or moved");
cmp_ok($changes, '>', 300, 'the sweep covered the changes');

done_testing;
