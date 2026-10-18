#!perl
use 5.010;
use strict;
use warnings;
use Test::More;
use utf8;
binmode Test::More->builder->$_, ':encoding(UTF-8)' for qw(output failure_output todo_output);

use Time::Keeper;

my $Y = 'Time::Keeper::YearMonth';
sub dies_like { my ($code, $re, $name) = @_; ok(!eval { $code->(); 1 }, $name) or return; like($@, $re, "$name: the message") }

my $ym = $Y->new(year => 2024, month => 2, locale => 'de');
isa_ok($ym, $Y, 'new');
is("$ym", '2024-02', 'stringifies');
is($ym->iso8601, '2024-02', 'iso8601');
is($ym->TO_JSON, '2024-02', 'TO_JSON');
is($ym->year, 2024, 'year');
is($ym->month, 2, 'month');
is($ym->quarter, 1, 'quarter');
is($ym->is_leap_year, 1, 'is_leap_year');
is($ym->days_in_month, 29, 'days_in_month (java: YearMonth.of(2024, 2).lengthOfMonth is 29)');
is($ym->days_in_year, 366, 'days_in_year');
is($ym->days_in_quarter, 91, 'days_in_quarter');
is($ym->locale, 'de', 'locale');
is($ym->month_name, 'Februar', 'month_name');
is($ym->month_abbr, 'Feb.', 'month_abbr');
is($ym->quarter_name, '1. Quartal', 'quarter_name');
is($ym->era_abbr, 'n. Chr.', 'era_abbr');
ok(!$ym->can('day'), 'no day');
ok(!$ym->can('day_of_week'), 'no day_of_week');
ok(!$ym->can('day_name'), 'no day_name');
ok(!$ym->can('next'), 'no weekday adjusters');
ok(!$ym->can('delta_days'), 'no delta_days');
dies_like(sub { $Y->new(year => 2024) }, qr/month is required/, 'month is required');
dies_like(sub { $Y->new(month => 2) }, qr/year is required/, 'year is required');
dies_like(sub { $Y->new(year => 2024, month => 13) }, qr/month/, 'month 13 dies');
dies_like(sub { $Y->new(year => 2024, month => 2, day => 1) }, qr/unknown argument 'day'/, 'no day key');

is($ym->plus(months => 11) . '', '2025-01', 'plus months across a year');
is($ym->plus(years => 1) . '', '2025-02', 'plus years');
is($ym->minus(months => 2) . '', '2023-12', 'minus months');
is(($ym + Time::Keeper::Duration->new(months => 1)) . '', '2024-03', '+ a duration');
is((Time::Keeper::Duration->new(years => 1) + $ym) . '', '2025-02', 'duration + year-month');
my $later = $Y->new(year => 2026, month => 10);
is(($later - $ym) . '', 'P2Y8M', 'the difference is months');
is(($ym + ($later - $ym)) . '', "$later", 'and adds back');
is($later->minus($ym) . '', 'P2Y8M', 'minus a year-month');
dies_like(sub { $ym->plus(days => 1) }, qr/a year and month has no day/, 'plus days dies');
dies_like(sub { $ym->plus(weeks => 1) }, qr/has no day/, 'plus weeks dies');
dies_like(sub { $ym->plus(hours => 1) }, qr/has no clock/, 'plus hours dies');
dies_like(sub { $ym + Time::Keeper::Duration->new(days => 1) }, qr/takes only the units it has/, '+ days dies');

is($ym->with(month => 12) . '', '2024-12', 'with month');
is($ym->with(year => 2000) . '', '2000-02', 'with year');
dies_like(sub { $ym->with(day => 3) }, qr/unknown argument 'day'/, 'with has no day');
is($ym->in_locale('fr')->month_name, 'février', 'in_locale');

is($ym->truncate(to => 'quarter') . '', '2024-01', 'truncate to quarter');
is($ym->truncate(to => 'year') . '', '2024-01', 'truncate to year');
is($ym->end_of(to => 'year') . '', '2024-12', 'end_of year');
is($ym->end_of(to => 'quarter') . '', '2024-03', 'end_of quarter');
is($Y->new(year => 2024, month => 8)->round(to => 'year') . '', '2025-01', 'round to year: August rounds up');
dies_like(sub { $ym->truncate(to => 'month') }, qr/truncated to a year or quarter, not to month/, 'not to month');
dies_like(sub { $ym->truncate(to => 'week') }, qr/not to week/, 'not to week');

is($ym->on(15) . '', '2024-02-15', 'on a day');
isa_ok($ym->on(15), 'Time::Keeper::Date', 'on gives a date');
is($ym->on(15)->locale, 'de', 'with the locale');
is($ym->on('last') . '', '2024-02-29', 'on last');
is($ym->last_day . '', '2024-02-29', 'last_day (java atEndOfMonth)');
dies_like(sub { $ym->on(30) }, qr/2024-02 has no day 30/, 'on a day it has not');

ok($ym < $later, '<');
is($Y->compare($later, $ym), 1, 'compare');
ok($ym == $Y->new(year => 2024, month => 2), '==');
dies_like(sub { my $x = $ym <=> Time::Keeper::Date->new(year => 2024, month => 2, day => 1) }, qr/compares only with another year and month/, 'not with a date');

is($ym->format('MMMM y'), 'Februar 2024', 'format');
is($ym->format('yyyy-MM'), '2024-02', 'numeric');
is($ym->format('QQQQ y'), '1. Quartal 2024', 'quarter');
dies_like(sub { $ym->format('d MMMM y') }, qr/'d' needs a day, and a year and month has none/, 'a day letter dies');
dies_like(sub { $ym->format('EEEE') }, qr/'E' needs a day/, 'a weekday letter dies');
dies_like(sub { $ym->format('HH') }, qr/'H' needs a time of day/, 'a time letter dies');
is($ym->strftime('%B %Y'), 'Februar 2024', 'strftime');
dies_like(sub { $ym->strftime('%d') }, qr/%d needs a day/, '%d dies');
dies_like(sub { $ym->strftime('%x') }, qr/%x needs a day/, '%x dies');
dies_like(sub { $ym->strftime('%F') }, qr/%F needs a day/, '%F dies');
is($ym->format_date, 'Feb. 2024', 'format_date medium is yMMM');
is($ym->format_date('full'), 'Februar 2024', 'full is yMMMM');
is($ym->format_date('short'), '2/2024', 'short is yM');
is($ym->in_locale('en')->format_date, 'Feb 2024', 'in English');
is($ym->format_skeleton('yMMM'), 'Feb. 2024', 'format_skeleton');
dies_like(sub { $ym->format_skeleton('yMMMd') }, qr/'d' needs a day/, 'a day skeleton dies');

is($Y->parse('2026-10') . '', '2026-10', 'parse');
is($Y->parse('2026-10', locale => 'fr')->locale, 'fr', 'with a locale');
dies_like(sub { $Y->parse('2026') }, qr/has no month/, 'a year alone dies');
dies_like(sub { $Y->parse('2026-10-15') }, qr/has a day, and a year and month has none/, 'a day dies');
dies_like(sub { $Y->parse('2026-W42') }, qr/has a day/, 'a week dies');
dies_like(sub { $Y->parse('2026-10T09:00') }, qr/cannot parse|has a time/, 'a time dies');
is($Y->strptime('10/2026', '%m/%Y') . '', '2026-10', 'strptime');
is($Y->strptime('15/10/2026', '%d/%m/%Y') . '', '2026-10', 'strptime drops a day the pattern read');
is($Y->parse_cldr('octobre 2026', 'MMMM y', locale => 'fr') . '', '2026-10', 'parse_cldr');
is($Y->try_parse('2026-10-15'), undef, 'try_parse');
ok($Y->try_new(year => 2026, month => 10), 'try_new');

my $frozen = $ym->FREEZE('any');
like($frozen, qr/^tkp1 3 \d+ 0 de$/, 'FREEZE text');
is($Y->THAW('any', $frozen) . '', '2024-02', 'THAW');
require Storable;
my $copy = Storable::thaw(Storable::freeze($ym));
isa_ok($copy, $Y, 'Storable');
is("$copy", '2024-02', 'round-trips');
dies_like(sub { $Y->THAW('any', 'tkp1 3 86400 0') }, qr/not a frozen/, 'a date that is not the first does not thaw');

is(Time::Keeper->new(year => 2026, month => 10, day => 15)->to_year_month . '', '2026-10', 'a value to_year_month');

done_testing;
