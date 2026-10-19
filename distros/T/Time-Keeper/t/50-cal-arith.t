#!perl
use 5.010;
use strict;
use warnings;
use Test::More;

use Time::Keeper;

my $K = 'Time::Keeper';
my $C = 'Time::Keeper::Calendar';
sub dies_like { my ($code, $re, $name) = @_; ok(!eval { $code->(); 1 }, $name) or return; like($@, $re, "$name: the message") }
sub cal { my ($t) = @_; sprintf '%d-%02d-%02d', $t->year, $t->month, $t->day }

my $adar1 = $K->new(year => 5784, month => 6, day => 30, calendar => 'hebrew');
is(cal($adar1), '5784-06-30', '30 Adar I 5784');
is($adar1->month_code, 'M05L', 'a leap month');
is(cal($adar1->plus(months => 12)), '5785-05-30', '12 ordinal months on: Shevat 5785, since 5784 has 13 months');
is(cal($adar1->plus(months => 13)), '5785-07-01', '13 months on is Adar 5785, which has 29 days, so day 30 wraps to 1 Nisan');
is(cal($adar1->plus(months => 13, end_of_month => 'limit')), '5785-06-29', 'with limit the 29th');
is(cal($adar1->plus(months => 13, end_of_month => 'wrap')), '5785-07-01', 'with wrap 1 Nisan');
is(cal($adar1->plus(years => 1)), '5785-07-01', 'a year on: Adar I becomes Adar in a year without one (ICU, Temporal), and day 30 wraps to 1 Nisan');
is($adar1->plus(years => 1, end_of_month => 'limit')->month_code, 'M06', 'with limit it is 29 Adar');
is(cal($adar1->plus(years => 1, end_of_month => 'limit')), '5785-06-29', 'the last day');
is(cal($adar1->plus(years => 3)), '5787-06-30', 'three years on 5787 is leap again: 30 Adar I');
is($adar1->plus(years => 3)->month_code, 'M05L', 'by its code');
is(cal($adar1->plus(years => 1, months => 1)), '5785-08-01', 'years first, then months: Adar (wrapped to 1 Nisan)... then one month, 1 Iyar');
is(cal($adar1->minus(months => 1)), '5784-05-30', 'minus a month is Shevat');
is(cal($adar1->minus(years => 1)), '5783-06-29', 'minus a year: 5783 has no Adar I, so Adar, cut to its 29th (minus keeps the last day)');
is(cal($adar1->plus(days => 1)), '5784-07-01', 'a day on is 1 Adar II');
is(cal($adar1->plus(weeks => 2)), '5784-07-14', 'two weeks: Adar I has 30 days');
is($adar1->plus(hours => 25)->hour, 1, 'the clock still works');
my $heshvan = $K->new(year => 5787, month => 2, day => 4, hour => 12, calendar => 'hebrew');
my $d = $heshvan - $adar1;
is("$d", 'P2Y8M4DT12H', 'the difference is months (printed as years and months by twelves) then days');
is($d->in_units('months'), 32, '32 ordinal months');
is(cal($adar1 + $d), cal($heshvan), 'and adds back (K12)');
is(($adar1 + $d)->epoch, $heshvan->epoch, 'to the instant');
is($heshvan->minus($adar1) . '', 'P2Y8M4DT12H', 'minus a value');
is($adar1->until($heshvan, largest => 'months') . '', 'P2Y8M4DT12H', 'until months');
is($adar1->until($heshvan, largest => 'days') . '', 'P949DT12H', 'until days');
is($adar1->until($heshvan, largest => 'hours') . '', 'PT22788H', 'until hours');
dies_like(sub { $adar1->until($heshvan, largest => 'years') }, qr/largest => 'years' in the hebrew calendar comes in a later release/, 'years need the ruling on durations');
is($heshvan->delta_md($adar1) . '', 'P2Y8M4D', 'delta_md in the calendar');
is($adar1->delta_days($heshvan) . '', 'P949D', 'delta_days');
is(cal($heshvan->truncate(to => 'year')), '5787-01-01', 'truncate to the calendar year');
is($heshvan->truncate(to => 'year')->iso8601, '2026-09-12T00:00:00Z', 'which is 12 September 2026');
is(cal($heshvan->truncate(to => 'month')), '5787-02-01', 'to the month');
is(cal($heshvan->truncate(to => 'quarter')), '5787-01-01', 'to the quarter');
is($heshvan->truncate(to => 'week')->iso8601, '2026-10-12T00:00:00Z', 'to the week, which is ISO and the same in every calendar');
is($heshvan->truncate(to => 'day')->iso8601, '2026-10-15T00:00:00Z', 'to the day');
is($heshvan->end_of(to => 'month')->iso8601, '2026-11-10T23:59:59.999999999Z', 'end_of month: Heshvan 5787 has 30 days');
is(cal($heshvan->end_of(to => 'month')), '5787-02-30', 'in the calendar');
is(cal($heshvan->end_of(to => 'year')), '5787-13-29', 'end_of year: 29 Elul, the 13th month of a leap year');
is(cal($heshvan->round(to => 'month')), '5787-02-01', 'round to the month: the 4th rounds down');
is(cal($K->new(year => 5787, month => 2, day => 20, calendar => 'hebrew')->round(to => 'month')), '5787-03-01', 'the 20th up to Kislev');
is(cal($K->new(year => 5787, month => 2, day => 16, calendar => 'hebrew')->round(to => 'month', mode => 'half_even')), '5787-02-01', 'half_even on the exact middle of a 30-day month goes to the even bucket');
is(cal($heshvan->round(to => 'year')), '5787-01-01', 'round to the year');
is(cal($heshvan->next(day_of_week => 1)), '5787-02-08', 'next Monday');
is(cal($heshvan->nth_in_month(day_of_week => 7, n => 1)), '5787-02-07', 'the first Sunday of Heshvan');
is(cal($heshvan->last_in_month(day_of_week => 7)), '5787-02-28', 'the last Sunday');
dies_like(sub { $heshvan->nth_in_month(day_of_week => 7, n => 5) }, qr/5787-02 has no fifth Sunday/, 'no fifth Sunday, named in the calendar');
is(scalar(my @m = $heshvan->range($heshvan->plus(months => 3), by => 'month')), 4, 'range by month in the calendar');
is(join(' ', map { cal($_) } @m), '5787-02-04 5787-03-04 5787-04-04 5787-05-04', 'the same day of each month');
is(scalar(my @y = $adar1->range($adar1->plus(months => 60), by => 'year')), 6, 'range by year, end included (a year is twelve ordinal months here, as a Duration has no years)');
is(($adar1 + Time::Keeper::Duration->new(years => 1))->month_code, 'M05', 'a Duration of a year is twelve months, so 30 Adar I plus one lands in Shevat: the documented surprise');

my $pagumen = $K->new(year => 1739, month => 13, day => 6, calendar => 'coptic');
is(cal($pagumen->plus(months => 1)), '1740-01-06', 'the 13th month plus one is the next year');
is(cal($pagumen->plus(years => 1)), '1741-01-01', 'plus a year: 1740 has a 5-day 13th month, so the 6th wraps');
is(cal($pagumen->plus(years => 1, end_of_month => 'limit')), '1740-13-05', 'or is cut to the 5th');
is(cal($pagumen->minus(years => 1)), '1738-13-05', 'minus keeps the last day');
is(cal($pagumen->truncate(to => 'quarter')), '1739-13-01', 'the 13th month is a quarter of its own');
is(cal($pagumen->end_of(to => 'quarter')), '1739-13-06', 'ending with it');
is(cal($pagumen->plus(months => 13)), '1741-01-01', '13 months is a year here, and the 6th wraps past the shorter month');
my $hijri = $K->new(year => 1445, month => 1, day => 30, calendar => 'islamic-civil');
is(cal($hijri->plus(months => 1)), '1445-03-01', '30 Muharram plus a month: Safar has 29, so it wraps');
is(cal($hijri->plus(months => 1, end_of_month => 'limit')), '1445-02-29', 'or is cut');
is(cal($hijri->plus(months => 11)), '1445-12-30', '30 Dhu al-Hijjah in a leap year');
is(cal($hijri->plus(years => 1, months => 11)), '1447-01-01', 'and the next year it wraps');
is($K->new(year => 1403, month => 12, day => 30, calendar => 'persian')->plus(years => 1, end_of_month => 'limit')->day, 29, 'Esfand 30 to a common year');
is(cal($K->new(year => 5785, month => 6, day => 29, calendar => 'hebrew')->plus(months => 1, end_of_month => 'preserve')), '5785-07-30', 'preserve: the last of Adar to the last of Nisan');
is(cal($K->new(year => 5785, month => 6, day => 29, calendar => 'hebrew')->plus(months => 1, end_of_month => 'limit')), '5785-07-29', 'limit: the 29th stays the 29th');
is(cal($K->new(year => 5785, month => 6, day => 29, calendar => 'hebrew')->plus(months => 1)), '5785-07-29', 'wrap: the same when the day fits');
is(cal($K->new(year => 1739, month => 12, day => 1, calendar => 'coptic')->end_of(to => 'quarter')), '1739-12-30', 'the fourth quarter of a 13-month year ends with its twelfth month');
is(cal($K->new(year => 1739, month => 12, day => 1, calendar => 'coptic')->plus(months => 1, end_of_month => 'limit')), '1739-13-01', 'and a month on is the thirteenth');
{
    my $bad = 0;
    for my $y (5600 .. 5900) {
        $bad++ if Time::Keeper::_cal_months_index('hebrew', $y + 1, 1) - Time::Keeper::_cal_months_index('hebrew', $y, 1) != $C->months_in_year('hebrew', $y);
    }
    is($bad, 0, 'the Hebrew month index advances by the months in each year, 5600 to 5900');
}

my %gregorian_same = map { $_ => 1 } qw(plus minus truncate round end_of next previous nth_in_month last_in_month until since range delta_days delta_md);
my $g = $K->new(year => 2026, month => 1, day => 31, hour => 9, zone => 'Europe/London');
is($g->plus(months => 1)->iso8601, $g->in_calendar('gregory')->plus(months => 1)->iso8601, 'the Gregorian path is untouched');
is($g->in_calendar('buddhist')->plus(months => 1)->iso8601, $g->plus(months => 1)->iso8601, 'the Buddhist calendar adds the same months as the Gregorian');
is($g->in_calendar('japanese')->plus(years => 1)->iso8601, $g->plus(years => 1)->iso8601, 'and the same years');
is($g->in_calendar('roc')->truncate(to => 'year')->iso8601, $g->truncate(to => 'year')->iso8601, 'and truncates to the same year');

for my $cal (grep { $C->kind($_) ne 'astronomical' } $C->ids) {
    my $bad = 0;
    for (1 .. 1500) {
        my $a = $K->from_epoch(int(rand(6e9)) - 2e9, calendar => $cal);
        my $b = $K->from_epoch(int(rand(6e9)) - 2e9, calendar => $cal);
        my $diff = $b - $a;
        $bad++ if ($a + $diff)->epoch != $b->epoch;
        my $md = $a->delta_md($b);
        $bad++ if $md->months < 0 || $md->days < 0;
    }
    is($bad, 0, "$cal: \$a + (\$b - \$a) == \$b and delta_md is never negative, over 1,500 pairs");
}

done_testing;
