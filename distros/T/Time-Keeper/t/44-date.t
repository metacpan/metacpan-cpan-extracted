#!perl
use 5.010;
use strict;
use warnings;
use Test::More;
use utf8;
binmode Test::More->builder->$_, ':encoding(UTF-8)' for qw(output failure_output todo_output);

use Time::Keeper;

my $D = 'Time::Keeper::Date';
my $K = 'Time::Keeper';
sub d { $D->new(year => $_[0], month => $_[1], day => $_[2]) }
sub dies_like { my ($code, $re, $name) = @_; ok(!eval { $code->(); 1 }, $name) or return; like($@, $re, "$name: the message") }

my $d = $D->new(year => 2026, month => 10, day => 15, locale => 'fr');
isa_ok($d, $D, 'new');
ok(!$d->isa('Time::Keeper'), 'a date is not a Time::Keeper');
is("$d", '2026-10-15', 'stringifies as the ISO date');
is($d->iso8601, '2026-10-15', 'iso8601');
is($d->TO_JSON, '2026-10-15', 'TO_JSON');
is($d->locale, 'fr', 'keeps its locale');
is($D->new(year => 2026, month => 10, day => 15)->locale, 'en', 'English by default');
is($D->last_day_of_month(year => 2024, month => 2) . '', '2024-02-29', 'last_day_of_month');
is($D->from_day_of_year(year => 2026, day_of_year => 288) . '', '2026-10-15', 'from_day_of_year');
is($D->from_iso_week(year => 2026, week => 42, day => 4) . '', '2026-10-15', 'from_iso_week');
is($D->from_iso_week(year => 2026, week => 1, day => 1) . '', '2025-12-29', 'from_iso_week: week 1 of 2026 starts in 2025');
is($D->from_epoch_days(20741) . '', '2026-10-15', 'from_epoch_days');
is($D->from_epoch_days(-1) . '', '1969-12-31', 'and before the epoch');
is($D->new(year => -43, month => 3, day => 15) . '', '-000043-03-15', 'a negative year, six digits as ISO 8601 expands it');
is($D->new(year => 12026, month => 1, day => 1) . '', '+012026-01-01', 'an expanded year');
dies_like(sub { $D->new(year => 2026, month => 2, day => 30) }, qr/2026-02 has no day 30/, 'a day the month has not');
dies_like(sub { $D->new(month => 2, day => 3) }, qr/year is required/, 'year is required');
dies_like(sub { $D->new(year => 2026, month => 2, day => 3, hour => 9) }, qr/unknown argument 'hour'/, 'no time keys');
dies_like(sub { $D->new(year => 2026, month => 2, day => 3, zone => 'UTC') }, qr/unknown argument 'zone'/, 'no zone');
is($D->try_new(year => 2026, month => 2, day => 30), undef, 'try_new gives undef');
ok($D->try_new(year => 2026, month => 2, day => 28), 'and a date');

my $t = $K->new(year => 2026, month => 10, day => 15, hour => 23, minute => 30, zone => 'UTC', locale => 'de');
my $from = $t->to_date;
isa_ok($from, $D, 'to_date');
is("$from", '2026-10-15', 'the wall-clock date');
is($from->locale, 'de', 'with the locale');
is($t->in_zone('Asia/Tokyo')->to_date . '', '2026-10-16', 'to_date of the same instant in Tokyo is the next day');
for my $m (qw(year month day day_of_week day_of_year quarter day_of_quarter week week_year week_of_month is_leap_year days_in_month days_in_year days_in_quarter is_weekend is_weekday)) {
    is($from->$m, $t->$m, "accessor $m agrees with the value's");
}
is($from->epoch_days, 20741, 'epoch_days');
is($from->week(locale => 1), $t->week(locale => 1), 'week(locale => 1)');
is($from->month_name, 'Oktober', 'month_name in the locale');
is($from->day_abbr, $t->day_abbr, 'day_abbr');
is($from->era_name, $t->era_name, 'era_name');
is($from->quarter_abbr, $t->quarter_abbr, 'quarter_abbr');
ok(!$from->can('hour'), 'no hour method');
ok(!$from->can('epoch'), 'no epoch method');
ok(!$from->can('in_zone'), 'no in_zone method');
ok(!$from->can('zone_name'), 'no zone_name method');
is($from->in_locale('fr')->month_name, 'octobre', 'in_locale');

is($d->with(day => 1) . '', '2026-10-01', 'with day');
is($d->with(day => 'last') . '', '2026-10-31', 'with day => last');
is($d->with(year => 2024, month => 2, day => 'last') . '', '2024-02-29', 'with year, month and last');
is($d->with(day_of_year => 1) . '', '2026-01-01', 'with day_of_year');
is($d->with(week => 1) . '', '2026-01-01', 'with week keeps the day of the week');
is($d->with(day_of_week => 7) . '', '2026-10-18', 'with day_of_week within the ISO week');
dies_like(sub { $d->with(hour => 1) }, qr/unknown argument 'hour'/, 'with has no time keys');
dies_like(sub { $d->with(month => 2, day => 30) }, qr/has no day 30/, 'with checks the day');

is($d->plus(months => 1) . '', '2026-11-15', 'plus months');
is($d->plus(days => 20) . '', '2026-11-04', 'plus days');
is($d->plus(weeks => 2) . '', '2026-10-29', 'plus weeks');
is($d->plus(years => 1) . '', '2027-10-15', 'plus years');
is($d->minus(months => 10) . '', '2025-12-15', 'minus months');
is(d(2026, 1, 31)->plus(months => 1) . '', '2026-03-03', 'the end of month wraps, as a value does');
is(d(2026, 1, 31)->plus(months => 1, end_of_month => 'limit') . '', '2026-02-28', 'end_of_month => limit');
is(d(2026, 3, 31)->minus(months => 1) . '', '2026-02-28', 'minus keeps the last day (DateTime\'s default)');
is(d(2026, 3, 31)->minus(months => 1, end_of_month => 'wrap') . '', '2026-03-03', 'unless told to wrap');
is(($d + Time::Keeper::Duration->new(days => 3)) . '', '2026-10-18', 'date + duration');
is((Time::Keeper::Duration->new(months => 1) + $d) . '', '2026-11-15', 'duration + date');
is(($d - Time::Keeper::Duration->new(days => 15)) . '', '2026-09-30', 'date - duration');
is($d->plus(Time::Keeper::Duration->new(months => 1, days => 2)) . '', '2026-11-17', 'plus a duration');
dies_like(sub { $d->plus(hours => 24) }, qr/a date has no clock/, 'plus hours dies');
dies_like(sub { $d->plus(Time::Keeper::Duration->new(minutes => 1)) }, qr/a date has no clock/, 'plus a clock duration dies');
dies_like(sub { $d + Time::Keeper::Duration->new(seconds => 1) }, qr/takes only the units it has/, '+ a clock duration dies');
dies_like(sub { $d->plus(days => 1, gap => 'forward') }, qr/unknown argument 'gap'/, 'no gap: a date has no zone');
dies_like(sub { Time::Keeper::Duration->new(days => 1) - $d }, qr/means nothing/, 'duration - date');
my $e = d(2027, 3, 1);
my $diff = $e - $d;
isa_ok($diff, 'Time::Keeper::Duration', '$b - $a');
is("$diff", 'P4M14D', 'months then days (K12)');
is(($d + $diff) . '', "$e", 'and adds back');
is($e->minus($d) . '', 'P4M14D', 'minus a date');
is(($d - $e) . '', '-P4M17D', 'the other way counts months first from the later date (K12), as values do');
is($d->delta_days($e) . '', 'P137D', 'delta_days');
is($e->delta_days($d) . '', 'P137D', 'in either order');
is($d->delta_md($e) . '', 'P4M14D', 'delta_md');
my @pairs = map { [d(2000 + int(rand 50), 1 + int(rand 12), 1 + int(rand 28)), d(2000 + int(rand 50), 1 + int(rand 12), 1 + int(rand 28))] } 1 .. 2000;
my $bad = grep { ($_->[0] + ($_->[1] - $_->[0]))->iso8601 ne $_->[1]->iso8601 } @pairs;
is($bad, 0, '$a + ($b - $a) == $b over 2,000 random pairs');

is($d->truncate(to => 'month') . '', '2026-10-01', 'truncate to month');
is($d->truncate(to => 'week') . '', '2026-10-12', 'truncate to week (Monday)');
is($d->truncate(to => 'week', week_start => 7) . '', '2026-10-11', 'week_start');
is($d->truncate(to => 'quarter') . '', '2026-10-01', 'quarter');
is($d->truncate(to => 'year') . '', '2026-01-01', 'year');
is($d->end_of(to => 'month') . '', '2026-10-31', 'end_of month is the last day');
is($d->end_of(to => 'year') . '', '2026-12-31', 'end_of year');
is($d->end_of(to => 'week') . '', '2026-10-18', 'end_of week is the Sunday');
is($d->round(to => 'month') . '', '2026-10-01', 'round to month: the 15th rounds down');
is(d(2026, 10, 17)->round(to => 'month') . '', '2026-11-01', 'the 17th up');
is(d(2026, 10, 16)->round(to => 'month', mode => 'floor') . '', '2026-10-01', 'mode => floor');
dies_like(sub { $d->truncate(to => 'day') }, qr/truncated to a year, quarter, month or week, not to day/, 'no day truncation');
dies_like(sub { $d->truncate(to => 'hour') }, qr/not to hour/, 'no hour truncation');
dies_like(sub { $d->round(to => 'month', increment => 2) }, qr/unknown argument 'increment'/, 'no increment');

is($d->next(day_of_week => 1) . '', '2026-10-19', 'next Monday');
is($d->next(day_of_week => 4) . '', '2026-10-22', 'next Thursday is a week on');
is($d->next(day_of_week => 4, or_same => 1) . '', '2026-10-15', 'or_same');
is($d->previous(day_of_week => 5) . '', '2026-10-09', 'previous Friday');
is($d->nth_in_month(day_of_week => 4, n => 4) . '', '2026-10-22', 'the fourth Thursday');
is($d->last_in_month(day_of_week => 7) . '', '2026-10-25', 'the last Sunday');
is($d->nth_in_month(day_of_week => 4, n => 5) . '', '2026-10-29', 'October 2026 has a fifth Thursday');
dies_like(sub { $d->nth_in_month(day_of_week => 7, n => 5) }, qr/no fifth/, 'but no fifth Sunday');

ok($d < $e, '< between dates');
ok($e > $d, '>');
ok($d == d(2026, 10, 15), '== by date');
is($d <=> $e, -1, '<=>');
is($D->compare($e, $d), 1, 'compare');
is((sort { $a <=> $b } $e, $d)[0] . '', "$d", 'sort');
dies_like(sub { my $x = $d <=> $t }, qr/a date compares only with another date/, 'no comparison with a value');
dies_like(sub { my $x = $d == Time::Keeper::YearMonth->new(year => 2026, month => 10) }, qr/only with another date/, 'nor with a year and month');
dies_like(sub { $D->compare($d, $t) }, qr/not a Time::Keeper::Date/, 'compare refuses a value');

my $at = $d->at(hour => 9, zone => 'Europe/London');
isa_ok($at, $K, 'at');
is($at->iso8601, '2026-10-15T09:00:00+01:00', 'the date at a time in a zone');
is($at->locale, 'fr', 'with the date\'s locale');
is($d->at->iso8601, '2026-10-15T00:00:00Z', 'at with nothing is midnight UTC');
is(d(2026, 3, 8)->at(zone => 'America/Sao_Paulo')->iso8601, '2026-03-08T00:00:00-03:00', 'midnight in Sao Paulo');
is(d(2018, 11, 4)->at(zone => 'America/Sao_Paulo')->iso8601, '2018-11-04T01:00:00-02:00', 'a skipped midnight gives the first moment, as today does');
dies_like(sub { d(2026, 3, 8)->at(hour => 2, minute => 30, zone => 'America/New_York') }, qr/did not happen/, 'a skipped time dies');
is(d(2026, 3, 8)->at(hour => 2, minute => 30, zone => 'America/New_York', gap => 'forward')->iso8601, '2026-03-08T03:30:00-04:00', 'unless gap => forward');
is($d->to_year_month . '', '2026-10', 'to_year_month');
is($d->to_month_day . '', '--10-15', 'to_month_day');
is(ref $d->to_year_month, 'Time::Keeper::YearMonth', 'as a YearMonth');
is(join(',', $d->utc_rd_values), '739904,0,0', 'utc_rd_values');
is($d->ymd, '2026-10-15', 'ymd');
is($d->ymd('/'), '2026/10/15', 'with a separator');
is($d->mdy, '10-15-2026', 'mdy');
is($d->dmy('.'), '15.10.2026', 'dmy');
is($d->date, '2026-10-15', 'date');
ok(!$d->can('hms'), 'no hms');

is($d->format('EEEE d MMMM y'), 'jeudi 15 octobre 2026', 'format in the locale');
is($d->format('yyyy-MM-dd'), '2026-10-15', 'numeric');
is($d->format('QQQ'), 'T4', 'quarter');
is($d->format("'at' d"), 'at 15', 'quoted text is not a letter');
dies_like(sub { $d->format('HH:mm') }, qr/the pattern letter 'H' needs a time of day, and a date has none/, 'a time letter dies');
dies_like(sub { $d->format('d MMM y z') }, qr/'z' needs a zone/, 'a zone letter dies');
dies_like(sub { $d->format('a') }, qr/'a' needs a time of day/, 'AM/PM dies');
is($d->strftime('%A %-d %B %Y'), 'jeudi 15 octobre 2026', 'strftime');
is($d->strftime('%F %j %G-W%V-%u'), '2026-10-15 288 2026-W42-4', 'date conversions');
is($d->strftime('%x'), '15 oct. 2026', '%x, the locale\'s date');
is($d->strftime('%%%n%t'), "%\n\t", 'the escapes');
dies_like(sub { $d->strftime('%H') }, qr/%H needs a time of day/, '%H dies');
dies_like(sub { $d->strftime('%T') }, qr/%T needs a time of day/, '%T dies');
dies_like(sub { $d->strftime('%c') }, qr/%c needs a date as well as a time of day/, '%c dies');
dies_like(sub { $d->strftime('%z') }, qr/%z needs a zone/, '%z dies');
dies_like(sub { $d->strftime('%s') }, qr/%s needs an instant/, '%s dies');
my @two = $d->format('y', 'MM');
is("@two", '2026 10', 'format lists several patterns');
is($d->format_date('full'), 'jeudi 15 octobre 2026', 'format_date full');
is($d->format_date, '15 oct. 2026', 'format_date medium');
is($d->format_date('short'), '15/10/2026', 'format_date short');
is($d->format_skeleton('yMMMd'), '15 oct. 2026', 'format_skeleton');
is($d->in_locale('en')->format_skeleton('yMMMEd'), 'Thu, Oct 15, 2026', 'in English');
dies_like(sub { $d->format_skeleton('Hm') }, qr/'H' needs a time of day/, 'a time skeleton dies');
dies_like(sub { $d->format_skeleton('nonsense') }, qr/no format for the skeleton 'nonsense'/, 'an unknown skeleton dies');

is($D->parse('2026-10-15') . '', '2026-10-15', 'parse');
is($D->parse('20261015') . '', '2026-10-15', 'basic');
is($D->parse('2026-W42-4') . '', '2026-10-15', 'week');
is($D->parse('2026-288') . '', '2026-10-15', 'ordinal');
is($D->parse('2026-10') . '', '2026-10-01', 'a month alone is its first day');
is($D->parse('2026-W42') . '', '2026-10-12', 'a week alone is its Monday');
is($D->parse('2026-10-15', locale => 'ja')->locale, 'ja', 'parse takes a locale');
dies_like(sub { $D->parse('2026-10-15T09:00') }, qr/has a time of day, and a date has none/, 'a time in the text dies');
dies_like(sub { $D->parse('2026-10-15Z') }, qr/text was left over|names a zone/, 'a Z dies');
dies_like(sub { $D->parse('2026-10-15T00:00Z') }, qr/has a time of day/, 'a time with a Z dies');
dies_like(sub { $D->parse('2026-10-15[Europe/London]') }, qr/names a zone/, 'a zone dies');
dies_like(sub { $D->parse('@1760000000') }, qr/is an instant/, 'an epoch dies');
dies_like(sub { $D->parse('yesterday') }, qr/cannot parse/, 'nonsense dies');
is($D->strptime('15/10/2026 09:30', '%d/%m/%Y %H:%M') . '', '2026-10-15', 'strptime keeps the date and drops the time the pattern read');
is($D->parse_cldr('15 octobre 2026', 'd MMMM y', locale => 'fr') . '', '2026-10-15', 'parse_cldr');
is($D->try_parse('2026-02-30'), undef, 'try_parse');
is($D->try_strptime('x', '%Y'), undef, 'try_strptime');
ok($D->try_parse_cldr('15 Oct 2026', 'd MMM y'), 'try_parse_cldr');
$@ = 'kept';
$D->try_parse('bad');
is($@, 'kept', 'try_ leaves $@ alone');

my $frozen = $d->FREEZE('any');
like($frozen, qr/^tkp1 1 \d+ 0 fr$/, 'FREEZE text');
my $back = $D->THAW('any', $frozen);
is("$back", "$d", 'THAW');
is($back->locale, 'fr', 'with the locale');
require Storable;
my $copy = Storable::thaw(Storable::freeze($d));
isa_ok($copy, $D, 'Storable');
is("$copy", '2026-10-15', 'round-trips');
is($copy->locale, 'fr', 'with its locale');
dies_like(sub { $D->THAW('any', $t->FREEZE('any')) }, qr/not a frozen Time::Keeper::Date/, 'a frozen value does not thaw as a date');
dies_like(sub { $D->THAW('any', Time::Keeper::YearMonth->new(year => 2026, month => 1)->FREEZE('any')) }, qr/not a frozen Time::Keeper::Date/, 'nor a frozen year and month');
dies_like(sub { $D->THAW('any', 'tkp1 1 43200 0') }, qr/not a frozen/, 'nor a non-midnight instant');

{
    my $forged = bless \(my $bytes = ${ $d }), 'Time::Keeper';
    ok(!eval { $forged->year; 1 }, 'a date\'s bytes blessed as a value are refused');
    like($@, qr/damaged/, 'as damaged');
    my $forged2 = bless \(my $bytes2 = ${ $t }), $D;
    ok(!eval { $forged2->year; 1 }, 'a value\'s bytes blessed as a date are refused');
    like($@, qr/damaged/, 'as damaged');
}

{
    package Time::Keeper::Date::Sub;
    our @ISA = ('Time::Keeper::Date');
}
my $sub = Time::Keeper::Date::Sub->new(year => 2026, month => 1, day => 1);
is(ref $sub->plus(days => 1), 'Time::Keeper::Date::Sub', 'a subclass survives arithmetic');
is(ref Time::Keeper::Date::Sub->parse('2026-01-01'), 'Time::Keeper::Date::Sub', 'and parsing');

my $today = $D->today;
isa_ok($today, $D, 'today');
is("$today", $K->now->to_date . '', 'is now\'s date in UTC');
is($D->today(zone => 'Asia/Tokyo') . '', $K->now(zone => 'Asia/Tokyo')->to_date . '', 'today in a zone');
{
    local $Time::Keeper::CLOCK = $K->parse('2026-10-15T23:30:00Z');
    is($D->today . '', '2026-10-15', 'today reads the test clock');
    is($D->today(zone => 'Asia/Tokyo') . '', '2026-10-16', 'in a zone');
}

done_testing;
