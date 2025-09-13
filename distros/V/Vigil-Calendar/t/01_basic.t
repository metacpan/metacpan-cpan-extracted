#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
#use FindBin;
#use lib "$FindBin::Bin/../lib";
use Vigil::Calendar;

my $cal = Vigil::Calendar->new(2025, 9);

is($cal->month, 9, 'month()');

is($cal->year, 2025, 'year()');

is($cal->previous_month_number, 8, 'previous_month_number()');

is($cal->previous_month_year, 2025, 'previous_month_year()');

is($cal->days_in_previous_month, 31, 'days_in_previous_month()');

is($cal->next_month_number, 10, 'next_month_year()');

is($cal->next_month_year, 2025, 'next_month_year()');

is($cal->days_in_next_month, 31, 'days_in_next_month()');

my $is_leap += 1 if $cal->is_a_leap_year(2028);
$is_leap += 1 unless $cal->is_a_leap_year(2031);
is($is_leap, 2, 'is_a_leap_year()');

is($cal->dayname(7, 5, 2026), 'Thursday', 'dayname()');

is($cal->weekday(7, 5, 2026), 5, 'weekday()');

is($cal->calendar_week(18), 3, 'calendar_week()');

is($cal->month_name(8), 'August', 'month_name()');

is($cal->month_number('April'), 4, 'month_number()');

is($cal->weeks_in_month(2026, 2), 4, 'weeks_in_month()');

is($cal->days_in_month(2028, 2), 29, 'days_in_month()');

is($cal->ordinal(22), 'nd', 'ordinal()');

is($cal->sse_from_ymd(2025, 9, 12), 1757646000, 'sse_from_ymd()');

done_testing();
