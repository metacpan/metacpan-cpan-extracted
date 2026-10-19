#!perl
use 5.010;
use strict;
use warnings;
use Test::More;

use Time::Keeper;
use Time::Keeper::Business;

my $C = 'Time::Keeper::Business';
sub d { Time::Keeper::Date->parse($_[0]) }
sub t { Time::Keeper->parse($_[0]) }
sub table { [Time::Keeper::Business::_hours_table($_[0])] }
sub spans { [map { [ "$_->[0]", "$_->[1]" ] } @_] }

# parsing
my $b = $C->new(zone => 'Europe/London',
    hours => { default => ['09:00-12:30', '13:30-17:30'], 5 => ['09:00-13:00'],
               '2026-12-24' => ['09:00-12:00'], '2026-12-31' => [] },
    holidays => ['2026-12-25', '2026-12-28'], name => 'london');
is_deeply(table($b), [
    'Monday: 32400-45000 48600-63000', 'Tuesday: 32400-45000 48600-63000', 'Wednesday: 32400-45000 48600-63000',
    'Thursday: 32400-45000 48600-63000', 'Friday: 32400-46800', 'Saturday: 32400-45000 48600-63000', 'Sunday: 32400-45000 48600-63000',
    '2026-12-24: 32400-43200', '2026-12-31:', 4 * 27000 + 14400,
], 'the table as parsed: the default on every weekday not named, the dated days, the weekly total') or diag explain table($b);
is_deeply(table($C->new(zone => 'UTC', hours => ['09:00-17:00'])), [(map { "$_: 32400-61200" } qw(Monday Tuesday Wednesday Thursday Friday Saturday Sunday)), 5 * 28800], 'a list is every day');
is_deeply([ @{ table($C->new(zone => 'UTC', hours => { mon => ['23:00-24:00'], TUE => ['00:00:30-00:01:00'] }, weekend => [3, 4, 5, 6, 7])) }[0, 1, 2] ], ['Monday: 82800-86400', 'Tuesday: 30-60', 'Wednesday:'], 'weekday names in any case, 24:00 as an end, seconds, no default when the rest are weekend days') or diag explain table($C->new(zone => 'UTC', hours => { mon => ['23:00-24:00'], TUE => ['00:00:30-00:01:00'] }, weekend => [3, 4, 5, 6, 7]));
is_deeply([ @{ table($C->new(zone => 'UTC', hours => { default => ['13:00-14:00', '09:00-10:00'] })) }[0] ], ['Monday: 32400-36000 46800-50400'], 'spans are sorted');
is_deeply([ @{ table($C->new(zone => 'UTC', hours => ['09:00-12:00', '12:00-17:00'])) }[0] ], ['Monday: 32400-43200 43200-61200'], 'adjacent spans are allowed');
is_deeply($b->hours, { default => ['09:00-12:30', '13:30-17:30'], 5 => ['09:00-13:00'], '2026-12-24' => ['09:00-12:00'], '2026-12-31' => [] }, 'the hours accessor gives the table as given');

my @refused = (
    [[hours => ['09:00-17:00']],                              qr/^Time::Keeper::Business->new: business hours need a zone/, 'hours without a zone'],
    [[zone => 'UTC', hours => 'nine to five'],                qr/hours are a list of 'HH:MM-HH:MM' spans, or a hash/, 'hours as a string'],
    [[zone => 'UTC', hours => ['nine-five']],                 qr/'nine-five' is not a span of hours 'HH:MM-HH:MM' for every day/, 'a span that is not one'],
    [[zone => 'UTC', hours => ['09:00-08:00']],               qr/the span '09:00-08:00' for every day ends before it starts/, 'a reversed span'],
    [[zone => 'UTC', hours => ['09:00-09:00']],               qr/ends before it starts/, 'an empty span'],
    [[zone => 'UTC', hours => ['09:00-25:00']],               qr/'09:00-25:00' is not a span/, 'past 24:00'],
    [[zone => 'UTC', hours => ['24:00-24:00']],               qr/ends before it starts/, 'a start of 24:00'],
    [[zone => 'UTC', hours => ['09:60-10:00']],               qr/is not a span/, 'a minute of 60'],
    [[zone => 'UTC', hours => ['09:00-12:00', '11:00-13:00']], qr/two spans of hours for every day overlap/, 'overlapping spans'],
    [[zone => 'UTC', hours => { mon => ['09:00-17:00'] }],     qr/the hours for Tuesday are not given and there is no default/, 'a weekday missing with no default'],
    [[zone => 'UTC', hours => { default => ['09:00-17:00'], tue => [] }], qr/the hours for Tuesday are empty: leave the key out, or make it a weekend day/, 'an empty weekday'],
    [[zone => 'UTC', hours => { default => ['09:00-17:00'], 8 => ['09:00-17:00'] }], qr/unknown hours key '8'/, 'a weekday of 8'],
    [[zone => 'UTC', hours => { default => ['09:00-17:00'], sunday => ['09:00-17:00'] }], qr/unknown hours key 'sunday'/, 'a long weekday name'],
    [[zone => 'UTC', hours => { default => ['09:00-17:00'], '2026-02-30' => [] }], qr/Time::Keeper::Date->parse/, 'a date that is not one'],
    [[zone => 'UTC', hours => { default => ['09:00-17:00'], '2026-12-24' => 'x' }], qr/the hours for 2026-12-24 are a list of 'HH:MM-HH:MM' spans/, 'a date with hours that are not a list'],
    [[zone => 'floating', hours => ['09:00-17:00']],          qr/a schedule's zone cannot be floating/, 'a floating zone'],
);
for my $r (@refused) {
    my ($args, $re, $why) = @$r;
    ok(!eval { $C->new(@$args); 1 }, "refused: $why");
    like($@, $re, '  with the message');
}

# no hours: every method dies by name
my $plain = $C->new;
for my $m (qw(is_business_hours next_open next_close previous_open previous_close business_hours_on)) {
    ok(!eval { $plain->$m(t('2026-10-15T10:00:00Z')); 1 }, "$m without hours dies");
    like($@, qr/^Time::Keeper::Business->$m: this schedule has no hours/, '  by name');
}

# the split
is_deeply([Time::Keeper::Business::_split($b, t('2026-10-15T10:00:00Z'))], [d('2026-10-15')->epoch_days, 11 * 3600, 0], '10:00 UTC is 11:00 in London in October');
is_deeply([Time::Keeper::Business::_split($b, t('2026-10-15T23:30:00Z'))], [d('2026-10-16')->epoch_days, 1800, 0], '23:30 UTC is 00:30 the next day in London');
is_deeply([Time::Keeper::Business::_split($b, Time::Keeper->new(year => 2016, month => 12, day => 31, hour => 23, minute => 59, second => 60, nanosecond => 5, zone => 'UTC'))],
          [d('2016-12-31')->epoch_days, 86399, 999999999], 'a leap second is the last instant of 23:59:59');

# is_business_hours and the four around a Thursday in London
my $thu = '2026-10-15';
sub L { Time::Keeper->new(year => 2026, month => 10, day => 15, hour => $_[0], minute => $_[1] // 0, second => $_[2] // 0, nanosecond => $_[3] // 0, zone => 'Europe/London') }
is($b->is_business_hours(L(8, 59)), 0, '08:59 is before the open');
is($b->is_business_hours(L(9)), 1, '09:00 is open');
is($b->is_business_hours(L(12, 29, 59, 999999999)), 1, 'the last instant before lunch is open');
is($b->is_business_hours(L(12, 30)), 0, '12:30 is lunch: a close is not open');
is($b->is_business_hours(L(12, 45)), 0, '12:45 is lunch');
is($b->is_business_hours(L(13, 30)), 1, '13:30 is open again');
is($b->is_business_hours(L(17, 29, 59)), 1, '17:29:59 is open');
is($b->is_business_hours(L(17, 30)), 0, '17:30 is closed');
is($b->is_business_hours(L(23, 59, 59, 999999999)), 0, 'the last instant of the day is closed');

is($b->next_open(L(12, 45)) . '', '2026-10-15T13:30:00+01:00', 'next_open in lunch is 13:30');
is($b->next_open(L(10)) . '', '2026-10-15T10:00:00+01:00', 'next_open when open is the moment itself');
ok(!$b->next_open(L(10))->isa('Time::Keeper::Business'), '  as a Time::Keeper');
is($b->next_open(L(17, 30)) . '', '2026-10-16T09:00:00+01:00', 'next_open at the close is the next morning');
is($b->next_open(L(8)) . '', '2026-10-15T09:00:00+01:00', 'next_open before the open is the open');
is($b->next_close(L(10)) . '', '2026-10-15T12:30:00+01:00', 'next_close when open is this span\'s close');
is($b->next_close(L(12, 45)) . '', '2026-10-15T17:30:00+01:00', 'next_close in lunch is the afternoon\'s close');
is($b->next_close(L(17, 30)) . '', '2026-10-16T13:00:00+01:00', 'next_close at the close is tomorrow\'s, a short Friday');
is($b->previous_close(L(12, 45)) . '', '2026-10-15T12:30:00+01:00', 'previous_close in lunch is 12:30');
is($b->previous_close(L(12, 30)) . '', '2026-10-15T12:30:00+01:00', 'previous_close at the stroke of a close is that close');
is($b->previous_close(L(10)) . '', '2026-10-14T17:30:00+01:00', 'previous_close in the morning is yesterday\'s');
is($b->previous_close(L(8)) . '', '2026-10-14T17:30:00+01:00', '  and before the open too');
is($b->previous_open(L(10)) . '', '2026-10-15T09:00:00+01:00', 'previous_open when open is this span\'s open');
is($b->previous_open(L(12, 45)) . '', '2026-10-15T09:00:00+01:00', 'previous_open in lunch is the morning\'s open');
is($b->previous_open(L(13, 30)) . '', '2026-10-15T13:30:00+01:00', 'previous_open at an open is that open');
is($b->previous_open(L(8)) . '', '2026-10-14T13:30:00+01:00', 'previous_open before the open is yesterday afternoon\'s');

# the short Friday, the dated days, the holiday, the weekend
my $fri = Time::Keeper->new(year => 2026, month => 10, day => 16, hour => 14, zone => 'Europe/London');
is($b->is_business_hours($fri), 0, 'Friday 14:00 is after the short day\'s close');
is($b->next_open($fri) . '', '2026-10-19T09:00:00+01:00', '  and the next open is Monday');
is($b->previous_close($fri) . '', '2026-10-16T13:00:00+01:00', '  and the previous close 13:00');
my $xmas_eve = Time::Keeper->new(year => 2026, month => 12, day => 24, hour => 11, zone => 'Europe/London');
is($b->next_close($xmas_eve) . '', '2026-12-24T12:00:00+00:00', 'Christmas Eve closes at noon by its dated list');
is($b->next_open(Time::Keeper->new(year => 2026, month => 12, day => 24, hour => 12, zone => 'Europe/London')) . '', '2026-12-29T09:00:00+00:00',
   '  and the next open is the 29th: the 25th and 28th are holidays, the 26th and 27th the weekend');
is($b->is_business_day(d('2026-12-31')), 1, 'New Year\'s Eve is a business day');
is_deeply(spans($b->business_hours_on(d('2026-12-31'))), [], '  with no hours');
is($b->next_open(Time::Keeper->new(year => 2026, month => 12, day => 30, hour => 18, zone => 'Europe/London')) . '', '2027-01-01T09:00:00+00:00',
   '  so the next open after the 30th is Friday 1 January, no holiday in this schedule');
my $with_hours_on_holiday = $b->with(hours => { default => ['09:00-17:00'], '2026-12-25' => ['10:00-11:00'] });
is_deeply(spans($with_hours_on_holiday->business_hours_on(d('2026-12-25'))), [], 'a holiday with a dated list stays closed');
is_deeply(spans($b->business_hours_on(d('2026-10-17'))), [], 'a Saturday has no hours');
is_deeply(spans($b->with(working => ['2026-10-17'])->business_hours_on(d('2026-10-17'))), [['2026-10-17T09:00:00+01:00', '2026-10-17T12:30:00+01:00'], ['2026-10-17T13:30:00+01:00', '2026-10-17T17:30:00+01:00']],
          'a worked Saturday takes the default');
is_deeply(spans($C->new(zone => 'UTC', hours => { mon => ['09:00-17:00'] }, weekend => [2 .. 7], working => ['2026-10-17'])->business_hours_on(d('2026-10-17'))), [],
          'a worked Saturday with no hours and no default has none');

# business_hours_on
is_deeply(spans($b->business_hours_on(d($thu))), [['2026-10-15T09:00:00+01:00', '2026-10-15T12:30:00+01:00'], ['2026-10-15T13:30:00+01:00', '2026-10-15T17:30:00+01:00']],
          'a Date gives the spans in the schedule\'s zone');
is_deeply(spans($b->business_hours_on(L(3))), [['2026-10-15T09:00:00+01:00', '2026-10-15T12:30:00+01:00'], ['2026-10-15T13:30:00+01:00', '2026-10-15T17:30:00+01:00']],
          'a Time::Keeper in the zone gives the same');
is_deeply(spans($b->business_hours_on(L(3)->in_zone('Asia/Tokyo'))), [['2026-10-15T17:00:00+09:00', '2026-10-15T20:30:00+09:00'], ['2026-10-15T21:30:00+09:00', '2026-10-16T01:30:00+09:00']],
          'a caller in Tokyo gets the same instants in Tokyo');
is($b->next_open(L(12, 45)->in_zone('Asia/Tokyo')) . '', '2026-10-15T21:30:00+09:00', '  as next_open does');
is($b->next_open(L(12, 45)->in_locale('fr'))->locale, 'fr', 'the locale is kept');
is($b->next_open(L(12, 45)->in_calendar('hebrew'))->calendar, 'hebrew', 'the calendar is kept');
{
    package My::Keeper;
    our @ISA = ('Time::Keeper');
}
is(ref $b->next_open(bless(L(12, 45), 'My::Keeper')), 'My::Keeper', 'a subclass is kept');
is_deeply(spans($C->new(zone => 'UTC', hours => ['00:00-24:00'], weekend => [])->business_hours_on(d('2026-10-15'))), [['2026-10-15T00:00:00Z', '2026-10-16T00:00:00Z']],
          'a close of 24:00 is the next day\'s midnight');
is_deeply(spans($b->business_hours_on(d('2026-10-15')->in_locale('de'))->[0][0]->locale eq 'de' ? [1] : [0]), [[1]], 'a Date\'s locale is kept') if 0;
is($b->business_hours_on(d('2026-10-15')->in_locale('de'))->[0]->locale, 'de', 'a Date\'s locale is kept');

# refusals of values
ok(!eval { $b->next_open(d($thu)); 1 }, 'a Date to next_open is refused');
like($@, qr/^Time::Keeper::Business->next_open: a date has no clock/, '  by name');
ok(!eval { $b->is_business_hours(Time::Keeper->new(year => 2026, month => 10, day => 15, hour => 10, zone => 'floating')); 1 }, 'a floating value is refused');
like($@, qr/a floating time has no zone to read business hours in/, '  by name');
ok(!eval { $b->business_hours_on(Time::Keeper::YearMonth->new(year => 2026, month => 10)); 1 }, 'a month is refused');

# the gap and the overlap in New York
my $ny = $C->new(zone => 'America/New_York', hours => ['02:00-04:00'], weekend => []);
is_deeply(spans($ny->business_hours_on(d('2026-03-08'))), [['2026-03-08T03:00:00-04:00', '2026-03-08T04:00:00-04:00']],
          '8 March 2026: an open of 02:00 did not happen and is carried to 03:00');
is($ny->next_open(Time::Keeper->new(year => 2026, month => 3, day => 8, hour => 1, zone => 'America/New_York')) . '', '2026-03-08T03:00:00-04:00', '  next_open from 01:00 is 03:00');
is($ny->is_business_hours(Time::Keeper->new(year => 2026, month => 3, day => 8, hour => 3, minute => 30, zone => 'America/New_York')), 1, '  03:30 is open');
my $ov = $C->new(zone => 'America/New_York', hours => ['01:00-02:00'], weekend => []);
is_deeply(spans($ov->business_hours_on(d('2026-11-01'))), [['2026-11-01T01:00:00-04:00', '2026-11-01T02:00:00-05:00']],
          '1 November 2026: one open, the earlier 01:00, and the close two wall-clock hours later');
is($ov->is_business_hours(Time::Keeper->new(year => 2026, month => 11, day => 1, hour => 1, minute => 30, zone => 'America/New_York', overlap => 'later')), 1,
   '  the later 01:30 is open too: the wall clock reads 01:30');
is($ov->next_close(Time::Keeper->new(year => 2026, month => 11, day => 1, hour => 1, minute => 30, zone => 'America/New_York', overlap => 'later')) . '', '2026-11-01T02:00:00-05:00', '  and closes at 02:00 EST');

# 24/7
my $always = $C->new(zone => 'UTC', hours => ['00:00-24:00'], weekend => []);
is($always->is_business_hours(t('2026-10-18T00:00:00Z')), 1, 'a 24/7 schedule is always open');
is($always->next_close(t('2026-10-18T10:00:00Z')) . '', '2026-10-19T00:00:00Z', '  and next_close is the next midnight');
is($always->previous_close(t('2026-10-18T10:00:00Z')) . '', '2026-10-18T00:00:00Z', '  previous_close the last');
is($always->previous_open(t('2026-10-18T10:00:00Z')) . '', '2026-10-18T00:00:00Z', '  previous_open the same');

# nothing within a year
my $never = $C->new(zone => 'UTC', hours => ['09:00-17:00'], weekend => [1 .. 7]);
ok(!eval { $never->next_open(t('2026-10-15T10:00:00Z')); 1 }, 'a schedule with no open day: next_open dies');
like($@, qr/^Time::Keeper::Business->next_open: no business hours within a year of 2026-10-15/, '  by name');
ok(!eval { $never->previous_close(t('2026-10-15T10:00:00Z')); 1 }, '  and previous_close');
is($never->is_business_hours(t('2026-10-15T10:00:00Z')), 0, '  but is_business_hours is simply no');

# lazy schedules and with
my $lazy = $C->new(zone => 'UTC', hours => ['09:00-17:00'], holidays => sub { "$_[0]-10-15" });
is($lazy->is_business_hours(t('2030-10-15T10:00:00Z')), 0, 'a generated holiday closes the day for the hours too');
is($lazy->next_open(t('2030-10-15T10:00:00Z')) . '', '2030-10-16T09:00:00Z', '  and next_open skips it');
my $moved = $b->with(zone => 'America/New_York');
is($moved->next_open(L(12, 45)) . '', '2026-10-15T14:00:00+01:00', 'with(zone) keeps the table and moves the wall clock: 12:45 London is 07:45 New York, before the open, so 09:00 New York is 14:00 London');
is($moved->zone, 'America/New_York', '  and says so');
is($b->with(hours => ['10:00-11:00'])->next_open(L(9)) . '', '2026-10-15T10:00:00+01:00', 'with(hours) replaces the table');

done_testing;
