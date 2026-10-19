#!perl
use 5.010;
use strict;
use warnings;
use Test::More;

# Arithmetic in every arithmetic calendar, by the properties plus and the
# difference must share: $a + ($b - $a) == $b over random pairs, a month
# added then taken back lands on the day or its month's last, truncate is
# idempotent and at or before, end_of is the nanosecond before the next
# truncation, a year by name is the year by month code. Author only.
use Time::Keeper;

my $N = $ENV{TK_ORACLE_N} || 20000;
my $K = 'Time::Keeper';
srand(20261018);
for my $cal (Time::Keeper::Calendar->ids) {
    my %bad;
    my ($lo, $span) = Time::Keeper::Calendar->kind($cal) eq 'astronomical' ? (-3.0e10, 6.1e10) : (-4e10, 8e10);
    for (1 .. $N) {
        my $a = $K->from_epoch(int(rand($span)) + $lo, calendar => $cal);
        my $b = $K->from_epoch(int(rand($span)) + $lo, calendar => $cal);
        my $d = $b - $a;
        $bad{k12}++ if ($a + $d)->epoch != $b->epoch;
        my $n = int(rand(40)) - 20;
        my $m = $a->plus(months => $n, end_of_month => 'limit');
        my $back = $m->minus(months => $n, end_of_month => 'limit');
        $bad{month_back}++ unless $back->day == $a->day || $m->day == $m->days_in_month;
        $bad{month_count}++ unless (Time::Keeper::_cal_months_index($cal, $m->year, $m->month) - Time::Keeper::_cal_months_index($cal, $a->year, $a->month)) == $n;
        for my $unit (qw(year quarter month)) {
            my $t = $a->truncate(to => $unit);
            $bad{"truncate $unit"}++ if $t->epoch > $a->epoch || $t->truncate(to => $unit)->epoch != $t->epoch || $t->day != 1;
            $bad{"end_of $unit"}++ if $a->end_of(to => $unit)->plus(nanoseconds => 1)->truncate(to => $unit)->epoch != $a->end_of(to => $unit)->plus(nanoseconds => 1)->epoch;
        }
        my $y = $a->plus(years => 1, end_of_month => 'limit');
        $bad{year_code}++ unless $y->year == $a->year + 1 && ($y->month_code eq $a->month_code || ($a->is_leap_month && $y->month_code eq ($cal eq 'hebrew' ? 'M06' : $a->month_code =~ s/L$//r)));
    }
    my $total = 0;
    $total += $bad{$_} for keys %bad;
    is($total, 0, "$cal: $N pairs hold every property") or diag(join ' ', map { "$_: $bad{$_}" } sort keys %bad);
}

done_testing;
