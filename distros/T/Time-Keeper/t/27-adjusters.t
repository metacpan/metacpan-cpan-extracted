#!perl
use 5.010;
use strict;
use warnings;
use Test::More;

use Time::Keeper;

my $K = 'Time::Keeper';
sub t { $K->new(@_) }
sub dies_like {
    my ($code, $re, $name) = @_;
    my $ok = eval { $code->(); 1 };
    ok(!$ok && $@ =~ $re, $name) or diag($ok ? 'it did not die' : "died with: $@");
}

# next and previous from every weekday to every weekday: 12 to 18 October 2026 is Monday to Sunday.
for my $from (12 .. 18) {
    my $t = t(year => 2026, month => 10, day => $from, hour => 9, minute => 30);
    for my $dow (1 .. 7) {
        my $n = $t->next(day_of_week => $dow);
        my $p = $t->previous(day_of_week => $dow);
        is($n->day_of_week, $dow, "next from $from to $dow lands on it");
        is($p->day_of_week, $dow, "previous from $from to $dow lands on it");
        my $ahead = ($n - $t)->in_units('days');
        my $back  = ($t - $p)->in_units('days');
        ok($ahead >= 1 && $ahead <= 7, "next is 1 to 7 days on ($ahead)");
        ok($back >= 1 && $back <= 7, "previous is 1 to 7 days back ($back)");
        is($n->hms, '09:30:00', 'the time of day is kept');
        my $ns = $t->next(day_of_week => $dow, or_same => 1);
        my $ps = $t->previous(day_of_week => $dow, or_same => 1);
        if ($dow == $t->day_of_week) {
            is("$ns", "$t", 'or_same gives the value back on its own day');
            is("$ps", "$t", 'both ways');
        }
        else {
            is("$ns", "$n", 'or_same changes nothing on another day');
            is("$ps", "$p", 'both ways');
        }
    }
}

# The nth weekday of a month, by hand. October 2026 begins on a Thursday; November on a Sunday.
{
    my $oct = t(year => 2026, month => 10, day => 15);
    is($oct->nth_in_month(day_of_week => 4, n => 1)->ymd, '2026-10-01', 'the first Thursday is the 1st');
    is($oct->nth_in_month(day_of_week => 4, n => 5)->ymd, '2026-10-29', 'October 2026 has a fifth Thursday');
    is($oct->nth_in_month(day_of_week => 7, n => -1)->ymd, '2026-10-25', 'the last Sunday, when Europe goes back');
    is($oct->last_in_month(day_of_week => 7)->ymd, '2026-10-25', 'last_in_month is the same');
    is($oct->nth_in_month(day_of_week => 3, n => 1)->ymd, '2026-10-07', 'the first Wednesday');
    my $nov = t(year => 2026, month => 11, day => 3, hour => 18);
    is($nov->nth_in_month(day_of_week => 4, n => 3)->ymd, '2026-11-19', 'the third Thursday of November');
    is($nov->nth_in_month(day_of_week => 4, n => 4) . '', '2026-11-26T18:00:00Z', 'Thanksgiving, at the same hour');
    is($nov->nth_in_month(day_of_week => 7, n => 1)->ymd, '2026-11-01', 'the first Sunday is the 1st');
    is($nov->nth_in_month(day_of_week => 7, n => 5)->ymd, '2026-11-29', 'and there is a fifth');
    is($nov->last_in_month(day_of_week => 1)->ymd, '2026-11-30', 'the last Monday is the 30th');
    dies_like(sub { $nov->nth_in_month(day_of_week => 4, n => 5) }, qr/nth_in_month: 2026-11 has no fifth Thursday/,
              'a fifth that does not exist');
    dies_like(sub { $nov->nth_in_month(day_of_week => 6, n => 5) }, qr/2026-11 has no fifth Saturday/, 'nor this one');
    is(t(year => 2026, month => 3, day => 1)->last_in_month(day_of_week => 7)->ymd, '2026-03-29', 'the last Sunday of March');
    is(t(year => 2028, month => 2, day => 1)->last_in_month(day_of_week => 2)->ymd, '2028-02-29',
       'February 2028 ends on a Tuesday');
    is(t(year => 2026, month => 1, day => 1)->nth_in_month(day_of_week => 1, n => 1)->ymd, '2026-01-05',
       'the first Monday of 2026');
    # Every month of 2026, against a count of the days.
    for my $m (1 .. 12) {
        my $t = t(year => 2026, month => $m, day => 10);
        for my $dow (1 .. 7) {
            my @days = grep { t(year => 2026, month => $m, day => $_)->day_of_week == $dow } 1 .. $t->days_in_month;
            for my $n (1 .. 5) {
                if ($n <= @days) {
                    is($t->nth_in_month(day_of_week => $dow, n => $n)->day, $days[$n - 1], "2026-$m: the $n. weekday $dow");
                }
                else {
                    dies_like(sub { $t->nth_in_month(day_of_week => $dow, n => $n) }, qr/has no fifth/, "2026-$m: no fifth weekday $dow");
                }
            }
            is($t->last_in_month(day_of_week => $dow)->day, $days[-1], "2026-$m: the last weekday $dow");
        }
    }
}

# Arguments.
{
    my $t = t(year => 2026, month => 10, day => 15);
    dies_like(sub { $t->next }, qr/next: day_of_week is required/, 'next wants a day');
    dies_like(sub { $t->previous(day_of_week => 0) }, qr/day_of_week 0 is out of range/, 'a day 1 to 7');
    dies_like(sub { $t->next(day_of_week => 8) }, qr/day_of_week 8 is out of range/, 'not 8');
    dies_like(sub { $t->next(dow => 1) }, qr/unknown argument 'dow'/, 'and only the keys it knows');
    dies_like(sub { $t->nth_in_month(day_of_week => 1) }, qr/n is required/, 'nth wants n');
    dies_like(sub { $t->nth_in_month(day_of_week => 1, n => 0) }, qr/not 0/, 'n is not 0');
    dies_like(sub { $t->nth_in_month(day_of_week => 1, n => 6) }, qr/n 6 is out of range/, 'nor 6');
    dies_like(sub { $t->nth_in_month(day_of_week => 1, n => -2) }, qr/n -2 is out of range/, 'nor -2');
    dies_like(sub { $t->last_in_month(day_of_week => 1, n => 1) }, qr/unknown argument 'n'/, 'last_in_month takes no n');
}

# Across the clocks changing: the time of day is kept, and a gap is the caller's choice.
{
    my $sat = t(year => 2026, month => 3, day => 7, hour => 2, minute => 30, zone => 'America/New_York');
    dies_like(sub { $sat->next(day_of_week => 7) }, qr/did not happen in America\/New_York/, '02:30 on Sunday did not happen');
    is($sat->next(day_of_week => 7, gap => 'forward') . '', '2026-03-08T03:30:00-04:00', 'forward');
    is($sat->next(day_of_week => 7, gap => 'backward') . '', '2026-03-08T01:30:00-05:00', 'backward');
    is($sat->nth_in_month(day_of_week => 7, n => 2, gap => 'forward') . '', '2026-03-08T03:30:00-04:00',
       'nth_in_month takes gap too');
    my $lon = t(year => 2026, month => 10, day => 20, hour => 1, minute => 30, zone => 'Europe/London');
    is($lon->next(day_of_week => 7) . '', '2026-10-25T01:30:00+01:00', 'into an overlap: the earlier');
    is($lon->next(day_of_week => 7, overlap => 'later') . '', '2026-10-25T01:30:00+00:00', 'or the later');
    is($lon->last_in_month(day_of_week => 7, overlap => 'later') . '', '2026-10-25T01:30:00+00:00', 'last_in_month too');
    is(t(year => 2026, month => 10, day => 15, hour => 9, zone => 'floating')->next(day_of_week => 1) . '',
       '2026-10-19T09:00:00', 'in floating time');
    is(t(year => 2026, month => 10, day => 15, locale => 'de')->next(day_of_week => 1)->locale, 'de', 'the locale is kept');
}

# with: the last day, and a day of the week.
{
    my $t = t(year => 2026, month => 1, day => 31, hour => 9);
    is($t->with(day => 'last') . '', '2026-01-31T09:00:00Z', 'the last of January is the 31st');
    is($t->with(month => 2, day => 'last') . '', '2026-02-28T09:00:00Z', 'month first, then the last day');
    is($t->with(year => 2028, month => 2, day => 'last') . '', '2028-02-29T09:00:00Z', 'in a leap year');
    is($t->with(day => '15') . '', '2026-01-15T09:00:00Z', 'a numeric string is a number');
    dies_like(sub { $t->with(day => 'first') }, qr/day is not an integer/, 'only last is a word');
    is(t(year => 2026, month => 1, day => 1)->with(day_of_week => 7)->ymd, '2026-01-04', 'Sunday of the week of 1 January 2026');
    is(t(year => 2026, month => 1, day => 1)->with(day_of_week => 1)->ymd, '2025-12-29', 'and its Monday is in 2025');
    is(t(year => 2024, month => 12, day => 30)->with(day_of_week => 7)->ymd, '2025-01-05', 'ISO week 1 of 2025 ends in January');
    is(t(year => 2026, month => 10, day => 15, hour => 9)->with(day_of_week => 4) . '', '2026-10-15T09:00:00Z',
       'its own day changes nothing');
    is(t(year => 2026, month => 10, day => 15)->with(month => 11, day => 1, day_of_week => 3)->ymd, '2026-10-28',
       'after the other fields: Sunday 1 November is in the ISO week that began on Monday 26 October');
    dies_like(sub { $t->with(day_of_week => 0) }, qr/day_of_week 0 is out of range/, '1 to 7');
}

# with: a day of the year, and an ISO week.
{
    my $thu = t(year => 2026, month => 10, day => 15, hour => 9);
    is($thu->with(week => 1) . '', '2026-01-01T09:00:00Z', 'week 1 of 2026, keeping Thursday: 1 January');
    is($thu->with(week => 1, day_of_week => 1) . '', '2025-12-29T09:00:00Z', 'and its Monday is in 2025');
    is($thu->with(week => 53) . '', '2026-12-31T09:00:00Z', '2026 has 53 weeks; the Thursday of the last is 31 December');
    is($thu->with(year => 2024, week => 10) . '', '2024-03-07T09:00:00Z', 'week 10 of 2024, a Thursday');
    is($thu->with(week => 42) . '', "$thu", 'its own week changes nothing');
    is(t(year => 2024, month => 2, day => 29, hour => 9)->with(year => 2025, day_of_year => 60) . '', '2025-03-01T09:00:00Z',
       'day 60 of 2025 from 29 February 2024: the day check is skipped for a date given this way');
    is($thu->with(day_of_year => 1) . '', '2026-01-01T09:00:00Z', 'day 1');
    is($thu->with(day_of_year => 365) . '', '2026-12-31T09:00:00Z', 'day 365');
    is(t(year => 2028)->with(day_of_year => 366) . '', '2028-12-31T00:00:00Z', 'day 366 of a leap year');
    dies_like(sub { $thu->with(day_of_year => 366) }, qr/2026 has no day 366/, 'but not of a common year');
    dies_like(sub { $thu->with(year => 2027, week => 53) }, qr/2027 has 52 ISO weeks, not 53/, 'a week the year has not');
    dies_like(sub { $thu->with(week => 1, day => 3) }, qr/day_of_year or week cannot be given with month, day or each other/, 'week with a day');
    dies_like(sub { $thu->with(day_of_year => 10, month => 3) }, qr/cannot be given with month/, 'day_of_year with a month');
    dies_like(sub { $thu->with(day_of_year => 10, week => 3) }, qr/or each other/, 'or each other');
    dies_like(sub { $thu->with(week => 0) }, qr/week 0 is out of range/, 'week 0');
}

done_testing;
