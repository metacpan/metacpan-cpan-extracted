#!perl
use 5.010;
use strict;
use warnings;
use Test::More;
use utf8;
binmode Test::More->builder->$_, ':encoding(UTF-8)' for qw(output failure_output todo_output);

use Time::Keeper;

my $M = 'Time::Keeper::MonthDay';
sub dies_like { my ($code, $re, $name) = @_; ok(!eval { $code->(); 1 }, $name) or return; like($@, $re, "$name: the message") }

my $md = $M->new(month => 2, day => 29, locale => 'es');
isa_ok($md, $M, 'new');
is("$md", '--02-29', 'stringifies as ISO --MM-DD');
is($md->iso8601, '--02-29', 'iso8601');
is($md->TO_JSON, '--02-29', 'TO_JSON');
is($md->month, 2, 'month');
is($md->day, 29, 'day');
is($md->locale, 'es', 'locale');
is($md->month_name, 'febrero', 'month_name');
is($md->month_abbr, 'feb', 'month_abbr');
ok(!$md->can('year'), 'no year');
ok(!$md->can('day_of_week'), 'no day_of_week');
ok(!$md->can('plus'), 'no plus');
ok(!$md->can('truncate'), 'no truncate');
ok(!$md->can('quarter'), 'no quarter');
ok(!$md->can('is_leap_year'), 'no is_leap_year');
dies_like(sub { $M->new(month => 2, day => 30) }, qr/--02-30 is not a day of any year/, 'a day no month has');
dies_like(sub { $M->new(month => 2) }, qr/day is required/, 'day is required');
dies_like(sub { $M->new(day => 2) }, qr/month is required/, 'month is required');
dies_like(sub { $M->new(year => 2026, month => 2, day => 3) }, qr/unknown argument 'year'/, 'no year key');
is($M->try_new(month => 2, day => 30), undef, 'try_new');

is($md->in_year(2024) . '', '2024-02-29', 'in_year');
isa_ok($md->in_year(2024), 'Time::Keeper::Date', 'in_year gives a date');
is($md->in_year(2024)->locale, 'es', 'with the locale');
dies_like(sub { $md->in_year(2027) }, qr/2027 has no --02-29/, 'java: MonthDay.of(2, 29).atYear(2027) dies');
is($md->in_year(2027, end_of_month => 'limit') . '', '2027-02-28', 'end_of_month => limit');
is($md->in_year(2027, end_of_month => 'wrap') . '', '2027-03-01', 'end_of_month => wrap');
is($M->new(month => 12, day => 31)->in_year(2027) . '', '2027-12-31', 'a day every year has');
is($M->new(month => 12, day => 31)->in_year(-1) . '', '-000001-12-31', 'in a negative year');

is($md->with(day => 1) . '', '--02-01', 'with day');
is($md->with(month => 3) . '', '--03-29', 'with month');
dies_like(sub { $md->with(month => 4, day => 31) }, qr/has no day 31/, 'with checks the day');
dies_like(sub { $md->with(year => 2026) }, qr/unknown argument 'year'/, 'no year');
is($md->in_locale('fr')->month_name, 'février', 'in_locale');

ok($md > $M->new(month => 2, day => 28), '>');
ok($md < $M->new(month => 3, day => 1), '<');
ok($md == $M->new(month => 2, day => 29), '==');
is($M->compare($md, $M->new(month => 1, day => 1)), 1, 'compare');
dies_like(sub { my $x = $md <=> Time::Keeper::Date->new(year => 1972, month => 2, day => 29) }, qr/compares only with another month and day/, 'not with a date');

is($md->format('MMMM d'), 'febrero 29', 'format');
is($md->format('d MMM'), '29 feb', 'abbreviated');
is($md->format('MM-dd'), '02-29', 'numeric');
dies_like(sub { $md->format('d MMMM y') }, qr/'y' needs a year, and a month and day has none/, 'a year letter dies');
dies_like(sub { $md->format('EEEE d MMMM') }, qr/'E' needs a day/, 'a weekday letter dies: it needs the year');
dies_like(sub { $md->format('D') }, qr/'D' needs a day/, 'the day of the year dies');
dies_like(sub { $md->format('QQQ') }, qr/'Q' needs a year/, 'a quarter dies');
is($md->strftime('%d %B'), '29 febrero', 'strftime');
dies_like(sub { $md->strftime('%Y') }, qr/%Y needs a year/, '%Y dies');
dies_like(sub { $md->strftime('%A') }, qr/%A needs a day/, '%A dies');
dies_like(sub { $md->strftime('%j') }, qr/%j needs a day/, '%j dies');
is($md->format_date, '29 feb', 'format_date medium is MMMd');
is($md->format_date('long'), '29 de febrero', 'long is MMMMd');
is($md->format_date('short'), '29/2', 'short is Md');
is($md->in_locale('en')->format_date, 'Feb 29', 'in English');
is($md->in_locale('en')->format_date('full'), 'February 29', 'full in English');
is($md->format_skeleton('MMMd'), '29 feb', 'format_skeleton');
dies_like(sub { $md->format_skeleton('yMMM') }, qr/'y' needs a year/, 'a year skeleton dies');

is($M->parse('--02-29') . '', '--02-29', 'parse --MM-DD');
is($M->parse('--0229') . '', '--02-29', 'parse --MMDD');
is($M->parse('02-29') . '', '--02-29', 'parse MM-DD');
is($M->parse('--12-31', locale => 'ja')->locale, 'ja', 'with a locale');
dies_like(sub { $M->parse('--02-30') }, qr/--02-30 is not a day/, 'a day no month has dies');
dies_like(sub { $M->parse('2026-02-29') }, qr/cannot parse '2026-02-29' as --MM-DD/, 'a full date dies');
dies_like(sub { $M->parse('--2-9') }, qr/cannot parse/, 'single digits die');
is($M->strptime('29/02/2027', '%d/%m/%Y') . '', '--02-29', 'strptime: the year read is dropped, so 29 February stands');
is($M->parse_cldr('29 de febrero', "d 'de' MMMM", locale => 'es') . '', '--02-29', 'parse_cldr');
is($M->try_parse('--02-30'), undef, 'try_parse');
ok($M->try_parse('--02-29'), 'and the good one');

my $frozen = $md->FREEZE('any');
like($frozen, qr/^tkp1 4 \d+ 0 es$/, 'FREEZE text');
is($M->THAW('any', $frozen) . '', '--02-29', 'THAW');
require Storable;
my $copy = Storable::thaw(Storable::freeze($md));
isa_ok($copy, $M, 'Storable');
is("$copy", '--02-29', 'round-trips');
is($copy->locale, 'es', 'with its locale');
dies_like(sub { $M->THAW('any', 'tkp1 4 0 0') }, qr/not a frozen/, 'a day outside the reference year does not thaw');

is(Time::Keeper->new(year => 2026, month => 10, day => 15)->to_month_day . '', '--10-15', 'a value to_month_day');
is(Time::Keeper::Date->new(year => 2024, month => 2, day => 29)->to_month_day->in_year(2028) . '', '2028-02-29', 'and round the loop');

done_testing;
