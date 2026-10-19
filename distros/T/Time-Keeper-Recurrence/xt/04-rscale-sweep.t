#!perl
use 5.010;
use strict;
use warnings;
use Test::More;
use Time::Keeper;
use Time::Keeper::Recurrence;

# For every calendar Time::Keeper has: fifty years of a MONTHLY
# BYMONTHDAY=-1 rule are the last day of each of its months, and fifty
# years of a YEARLY BYYEARDAY=-1 rule the last day of each of its years,
# as Time::Keeper's own calendar arithmetic gives them. TKR_SWEEP_YEARS
# shortens or lengthens the span.

my $R = 'Time::Keeper::Recurrence';
my $years = $ENV{TKR_SWEEP_YEARS} || 50;
my ($months_checked, $years_checked) = (0, 0);

for my $cal (Time::Keeper::Calendar->ids) {
    my $first = Time::Keeper->new(year => 2000, month => 1, day => 1, zone => 'UTC')->in_calendar($cal);
    my $y0 = $first->year + 1;
    my $start = Time::Keeper->new(year => $y0, month => 1, day => 1, calendar => $cal, zone => 'UTC');
    my $end = Time::Keeper->new(year => $y0 + $years, month => 1, day => 1, calendar => $cal, zone => 'UTC');

    my @want;
    my $t = $start;
    while ($t->epoch < $end->epoch) {
        push @want, $t->plus(days => $t->days_in_month - 1)->epoch;
        $t = $t->plus(days => $t->days_in_month);
    }
    my $m = $R->new(rrule => 'RSCALE=' . uc($cal) . ';FREQ=MONTHLY;BYMONTHDAY=-1', start => $start);
    my @got = map { $_->epoch } grep { $_->epoch != $start->epoch } $m->between($start, $end);
    is_deeply(\@got, \@want, "$cal: the last day of each of " . scalar(@want) . " months") or diag("first difference near " . join(' ', map { Time::Keeper->from_epoch($_)->ymd } @got[0 .. 3]));
    $months_checked += @want;

    my @ywant = map { Time::Keeper->new(year => $_ + 1, month => 1, day => 1, calendar => $cal, zone => 'UTC')->minus(days => 1)->epoch } $y0 .. $y0 + $years - 1;
    my $yr = $R->new(rrule => 'RSCALE=' . uc($cal) . ';FREQ=YEARLY;BYYEARDAY=-1', start => $start);
    my @ygot = map { $_->epoch } grep { $_->epoch != $start->epoch } $yr->between($start, $end);
    is_deeply(\@ygot, \@ywant, "$cal: the last day of each of $years years");
    $years_checked += @ywant;
}
diag("$months_checked months and $years_checked years checked");
done_testing;
