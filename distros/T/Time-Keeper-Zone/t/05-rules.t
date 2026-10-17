#!perl
use 5.010;
use strict;
use warnings;
use Test::More;

use Time::Keeper::Zone;

# The TZ string evaluator on its own, with rules made up here: the forms
# 2026e's zones do not use today (Jn, n, all-year daylight time, rule times
# that cross into another year) as much as those they do.

sub days {
    my ($y, $m, $d) = @_;
    $y -= $m <= 2;
    my $era = int(($y >= 0 ? $y : $y - 399) / 400);
    my $yoe = $y - $era * 400;
    my $doy = int((153 * ($m > 2 ? $m - 3 : $m + 9) + 2) / 5) + $d - 1;
    return $era * 146097 + $yoe * 365 + int($yoe / 4) - int($yoe / 100) + $doy - 719468;
}
sub midnight { days(@_) * 86400 }
sub rule { Time::Keeper::Zone::_rule_local(@_) }

# Jn: 1 to 365, 29 February never counted.
is(rule('J', 0, 0, 0, 59, 0, 2024), midnight(2024, 2, 28), 'J59 is 28 February in a leap year');
is(rule('J', 0, 0, 0, 60, 0, 2024), midnight(2024, 3, 1), 'J60 is 1 March, 29 February skipped');
is(rule('J', 0, 0, 0, 60, 0, 2023), midnight(2023, 3, 1), 'and 1 March in a common year');
is(rule('J', 0, 0, 0, 365, 0, 2024), midnight(2024, 12, 31), 'J365 is 31 December');
is(rule('J', 0, 0, 0, 1, 0, 2024), midnight(2024, 1, 1), 'J1 is 1 January');

# n: 0 to 365, 29 February counted.
is(rule('n', 0, 0, 0, 0, 0, 2024), midnight(2024, 1, 1), 'day 0 is 1 January');
is(rule('n', 0, 0, 0, 59, 0, 2024), midnight(2024, 2, 29), 'day 59 is 29 February in a leap year');
is(rule('n', 0, 0, 0, 59, 0, 2023), midnight(2023, 3, 1), 'and 1 March in a common year');
is(rule('n', 0, 0, 0, 59, 0, 2000), midnight(2000, 2, 29), '2000 is a leap year');
is(rule('n', 0, 0, 0, 59, 0, 1900), midnight(1900, 3, 1), '1900 is not');
is(rule('n', 0, 0, 0, 59, 0, 2100), midnight(2100, 3, 1), 'nor is 2100');
is(rule('J', 0, 0, 0, 60, 0, 2000), midnight(2000, 3, 1), 'J60 in 2000 is still 1 March');

# Mm.w.d.
is(rule('M', 3, 5, 0, 0, 3600, 2026), midnight(2026, 3, 29) + 3600, 'M3.5.0/1: last Sunday in March 2026, 01:00');
is(rule('M', 3, 2, 0, 0, 7200, 2026), midnight(2026, 3, 8) + 7200, 'M3.2.0: second Sunday in March 2026');
is(rule('M', 2, 5, 4, 0, 0, 2100), midnight(2100, 2, 25), 'last Thursday in February 2100, a common year');
is(rule('M', 2, 5, 2, 0, 0, 2000), midnight(2000, 2, 29), 'last Tuesday in February 2000 is the 29th');
is(rule('M', 2, 5, 2, 0, 0, 1900), midnight(1900, 2, 27), 'and in 1900 the 27th');
is(rule('M', 1, 1, 0, 0, 0, 1700), midnight(1700, 1, 3), 'first Sunday in 1700');

# Times outside 0 to 24 hours (RFC 9636).
is(rule('M', 3, 5, 0, 0, -3600, 2026), midnight(2026, 3, 29) - 3600, 'a negative time is the day before');
is(rule('M', 4, 5, 5, 0, 167 * 3600, 2026), midnight(2026, 4, 24) + 167 * 3600, '167 hours runs a week on');

# Whole footers made up here. One hour ahead of UTC, DST two.
sub footer { [Time::Keeper::Zone::_footer_eval(3600, 7200, @_)] }
my $eu = ['M', 3, 5, 0, 0, 7200];
my $eu_end = ['M', 10, 5, 0, 0, 10800];
is_deeply(footer($eu, $eu_end, midnight(2026, 7, 1)), [1, midnight(2026, 10, 25) + 3600], 'summer, ending on 25 October at 01:00 UTC');
is_deeply(footer($eu, $eu_end, midnight(2026, 1, 1)), [0, midnight(2026, 3, 29) + 3600], 'winter, ending on 29 March');
is_deeply(footer($eu, $eu_end, midnight(1960, 7, 1)), [1, midnight(1960, 10, 30) + 3600], 'the same rule in 1960, before 1970');
is_deeply(footer($eu, $eu_end, midnight(1600, 7, 1))->[0], 1, 'and in 1600');

# Southern hemisphere: DST across the new year.
my $south_start = ['M', 10, 1, 0, 0, 7200];
my $south_end = ['M', 4, 1, 0, 0, 10800];
is(footer($south_start, $south_end, midnight(2026, 1, 1))->[0], 1, 'DST on New Year\'s Day in the south');
is(footer($south_start, $south_end, midnight(2026, 7, 1))->[0], 0, 'and not in July');
is(footer($south_start, $south_end, midnight(2026, 12, 31) + 86399)->[0], 1, 'nor at the last second of the year');

# Daylight time all year: it starts on 1 January at 00:00 standard time
# and ends at 25:00 daylight time on 31 December, which is the same
# instant. POSIX reads that as never leaving daylight time.
my $all_start = ['n', 0, 0, 0, 0, 0];
my $all_end = ['J', 0, 0, 0, 365, 25 * 3600];
for my $t (midnight(2026, 1, 1) - 1, midnight(2026, 1, 1), midnight(2026, 1, 1) + 1, midnight(2026, 6, 1), midnight(2026, 12, 31) + 86399) {
    is(footer($all_start, $all_end, $t)->[0], 1, "daylight time all year: at $t");
}

# A rule time that pushes a transition into the next year: DST starts on
# the last day of the year at 30:00, which is 06:00 on 1 January.
my $late_start = ['J', 0, 0, 0, 365, 30 * 3600];
my $late_end = ['M', 3, 5, 0, 0, 10800];
is(footer($late_start, $late_end, midnight(2027, 1, 1) + 2 * 3600)->[0], 0, 'before a start pushed into the new year');
is(footer($late_start, $late_end, midnight(2027, 1, 1) + 6 * 3600)->[0], 1, 'and after it');
is(footer($late_start, $late_end, midnight(2026, 12, 31) + 12 * 3600)->[1], midnight(2027, 1, 1) + 5 * 3600,
   'whose instant is 05:00 UTC on 1 January');

done_testing;
