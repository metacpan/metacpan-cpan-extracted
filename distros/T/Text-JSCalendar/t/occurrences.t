#!perl -T
use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More;
use JSON::XS ();
use Text::JSCalendar;

# occurrences() expands a recurring event (jscalendarbis-22 3.3.3.1) and
# instance() gives one occurrence of it.  Most expected sets are the
# RFC 5545 3.8.5.3 and RFC 7529 examples, in JSCalendar terms.

my $jscal = Text::JSCalendar->new();
my $T = JSON::XS::true;

sub occ {
  my ($start, $rule, %opts) = @_;
  my $overrides = delete $opts{overrides};
  return [ $jscal->occurrences({
    start => $start, timeZone => 'America/New_York',
    $rule ? (recurrenceRule => { '@type' => 'RecurrenceRule', %$rule }) : (),
    $overrides ? (recurrenceOverrides => $overrides) : (),
  }, %opts) ];
}
sub days { [ map { "${_}T09:00:00" } @_ ] }

is_deeply(occ('1997-09-02T09:00:00', { frequency => 'daily', count => 10 }),
  days(map { sprintf '1997-09-%02d', $_ } 2 .. 11), 'daily for 10 occurrences');
is_deeply(occ('1997-09-02T09:00:00', { frequency => 'daily', until => '1997-09-05T09:00:00' }),
  days(map { sprintf '1997-09-%02d', $_ } 2 .. 5), 'daily until, inclusive');
is_deeply(occ('1997-09-02T09:00:00', { frequency => 'daily', interval => 10, count => 5 }),
  days(qw(1997-09-02 1997-09-12 1997-09-22 1997-10-02 1997-10-12)), 'every 10 days, 5 occurrences');
is_deeply(occ('1997-09-02T09:00:00', { frequency => 'weekly', count => 4 }),
  days(qw(1997-09-02 1997-09-09 1997-09-16 1997-09-23)), 'weekly, the start weekday implied');
is_deeply(occ('1997-08-05T09:00:00', { frequency => 'weekly', interval => 2, count => 4,
    byDay => [{ day => 'tu' }, { day => 'su' }] }),
  days(qw(1997-08-05 1997-08-10 1997-08-19 1997-08-24)), 'every other week on tu, su (week starts monday)');
is_deeply(occ('1997-08-05T09:00:00', { frequency => 'weekly', interval => 2, count => 4,
    byDay => [{ day => 'tu' }, { day => 'su' }], firstDayOfWeek => 'su' }),
  days(qw(1997-08-05 1997-08-17 1997-08-19 1997-08-31)), '... and with firstDayOfWeek su');
is_deeply(occ('1997-09-05T09:00:00', { frequency => 'monthly', count => 6,
    byDay => [{ day => 'fr', nthOfPeriod => 1 }] }),
  days(qw(1997-09-05 1997-10-03 1997-11-07 1997-12-05 1998-01-02 1998-02-06)), 'monthly on the first friday');
is_deeply(occ('1997-09-07T09:00:00', { frequency => 'monthly', interval => 2, count => 6,
    byDay => [{ day => 'su', nthOfPeriod => 1 }, { day => 'su', nthOfPeriod => -1 }] }),
  days(qw(1997-09-07 1997-09-28 1997-11-02 1997-11-30 1998-01-04 1998-01-25)), 'every other month on the first and last sunday');
is_deeply(occ('1997-09-28T09:00:00', { frequency => 'monthly', count => 6, byMonthDay => [-3] }),
  days(qw(1997-09-28 1997-10-29 1997-11-28 1997-12-29 1998-01-29 1998-02-26)), 'monthly on the third-to-last day');
is_deeply(occ('1997-01-01T09:00:00', { frequency => 'yearly', interval => 3, count => 10, byYearDay => [1, 100, 200] }),
  days(qw(1997-01-01 1997-04-10 1997-07-19 2000-01-01 2000-04-09 2000-07-18 2003-01-01 2003-04-10 2003-07-19 2006-01-01)),
  'every third year on days 1, 100, 200');
is_deeply(occ('1997-05-19T09:00:00', { frequency => 'yearly', count => 3, byDay => [{ day => 'mo', nthOfPeriod => 20 }] }),
  days(qw(1997-05-19 1998-05-18 1999-05-17)), 'yearly on the 20th monday');
is_deeply(occ('1997-05-12T09:00:00', { frequency => 'yearly', count => 3, byWeekNo => [20] }),
  days(qw(1997-05-12 1998-05-11 1999-05-17)), 'monday of week 20 (the weekday implied)');
is_deeply(occ('2026-12-28T09:00:00', { frequency => 'yearly', count => 3, byWeekNo => [-1], byDay => [{ day => 'fr' }] }),
  days(qw(2026-12-28 2027-01-01 2027-12-31)), 'byWeekNo -1 is matched by week-year (2027-01-01 is in week 53 of 2026)');
is_deeply(occ('1997-03-13T09:00:00', { frequency => 'yearly', count => 3, byMonth => ['3'], byDay => [{ day => 'th' }] }),
  days(qw(1997-03-13 1997-03-20 1997-03-27)), 'every thursday in march');
is_deeply(occ('1997-09-29T09:00:00', { frequency => 'monthly', count => 3,
    byDay => [map { { day => $_ } } qw(mo tu we th fr)], bySetPosition => [-1] }),
  days(qw(1997-09-29 1997-09-30 1997-10-31)), 'the last workday of the month (the start, not an occurrence of the rule, still first and counted)'
  );
is_deeply(occ('1997-09-02T09:00:00', { frequency => 'hourly', interval => 3, until => '1997-09-02T17:00:00' }),
  [qw(1997-09-02T09:00:00 1997-09-02T12:00:00 1997-09-02T15:00:00)], 'every 3 hours until 17:00');
is_deeply(occ('1997-09-02T09:00:00', { frequency => 'minutely', interval => 20, count => 4, byHour => [9, 10] }),
  [qw(1997-09-02T09:00:00 1997-09-02T09:20:00 1997-09-02T09:40:00 1997-09-02T10:00:00)], 'every 20 minutes from 9 to 10');
is_deeply(occ('1997-09-02T09:00:00', { frequency => 'daily', count => 4, byHour => [9, 17], byMinute => [0, 30] }),
  [qw(1997-09-02T09:00:00 1997-09-02T09:30:00 1997-09-02T17:00:00 1997-09-02T17:30:00)], 'byHour and byMinute expand a day');

# skip (RFC 7529 4.3)
is_deeply(occ('2014-01-31T09:00:00', { frequency => 'monthly', count => 4, byMonthDay => [31] }),
  days(qw(2014-01-31 2014-03-31 2014-05-31 2014-07-31)), 'byMonthDay 31 omits short months');
is_deeply(occ('2014-01-31T09:00:00', { frequency => 'monthly', count => 4, rscale => 'gregorian', skip => 'backward' }),
  days(qw(2014-01-31 2014-02-28 2014-03-31 2014-04-30)), 'skip backward');
is_deeply(occ('2014-01-31T09:00:00', { frequency => 'monthly', count => 4, rscale => 'gregorian', skip => 'forward' }),
  days(qw(2014-01-31 2014-03-01 2014-03-31 2014-05-01)), 'skip forward');
is_deeply(occ('2016-02-29T09:00:00', { frequency => 'yearly', count => 3, rscale => 'gregorian', skip => 'forward' }),
  days(qw(2016-02-29 2017-03-01 2018-03-01)), 'a leap day, skip forward');
is_deeply(occ('2016-02-29T09:00:00', { frequency => 'yearly', count => 3 }),
  days(qw(2016-02-29 2020-02-29 2024-02-29)), 'a leap day, omitted');
ok(!eval { occ('2016-02-29T09:00:00', { frequency => 'yearly', rscale => 'hebrew' }); 1 }, 'another rscale dies');

# overrides, bounds and limits
is_deeply(occ('2025-01-01T09:00:00', { frequency => 'daily', count => 5 }, overrides => {
    '2025-01-02T09:00:00' => { excluded => $T },
    '2025-01-03T09:00:00' => { title => 'patched' },
    '2025-01-10T12:00:00' => {},
  }),
  [qw(2025-01-01T09:00:00 2025-01-03T09:00:00 2025-01-04T09:00:00 2025-01-05T09:00:00 2025-01-10T12:00:00)],
  'excluded ids are removed, added ones included, patched ones kept once');
is_deeply(occ('2025-01-01T09:00:00', undef, overrides => { '2025-02-01T09:00:00' => {} }),
  [qw(2025-01-01T09:00:00 2025-02-01T09:00:00)], 'a non-recurring event: its start and its added occurrences');
is_deeply(occ('2020-01-01T09:00:00', { frequency => 'daily' }, after => '2026-01-01', before => '2026-01-04T09:00:00'),
  days(qw(2026-01-01 2026-01-02 2026-01-03)), 'after is inclusive, before exclusive');
is_deeply(occ('2020-01-01T09:00:00', { frequency => 'daily', count => 3 }, after => '2020-01-02T00:00:00Z'),
  days(qw(2020-01-02 2020-01-03)), 'a count counts from the start, whatever after says');
is(scalar @{occ('2025-01-01T09:00:00', { frequency => 'daily' })}, 5000, 'an unbounded rule stops at 5000');
is(scalar @{occ('2025-01-01T09:00:00', { frequency => 'secondly' }, max => 10)}, 10, '... or at max');
is_deeply(occ('2025-01-01T09:00:00', { frequency => 'yearly', byMonth => ['2'], byMonthDay => [30] }),
  ['2025-01-01T09:00:00'], 'a rule that never matches ends');
is_deeply(occ('2000-01-01T09:30:00', { frequency => 'hourly' }, after => '2026-01-01T22:00:00', before => '2026-01-02T01:00:00'),
  [qw(2026-01-01T22:30:00 2026-01-01T23:30:00 2026-01-02T00:30:00)], 'a range far from the start');

# a synthetic master: its instances
my ($sm) = $jscal->vcalendarToEvents(join("\r\n", 'BEGIN:VCALENDAR', 'VERSION:2.0', 'PRODID:x',
  (map { ('BEGIN:VEVENT', 'UID:s@example.com', 'DTSTAMP:20250101T000000Z',
          "RECURRENCE-ID:${_}T090000Z", "DTSTART:${_}T100000Z", 'END:VEVENT') } qw(20250312 20250319)),
  'END:VCALENDAR', ''));
is_deeply([$jscal->occurrences($sm)], [qw(2025-03-12T09:00:00 2025-03-19T09:00:00)], 'a synthetic master has its instances');

# --- instance

my $master = {
  '@type' => 'Event', uid => 'm@example.com', title => 'Weekly', start => '2025-01-06T09:00:00',
  timeZone => 'Europe/Berlin', duration => 'PT1H',
  recurrenceRule => { '@type' => 'RecurrenceRule', frequency => 'weekly' },
  participants => {
    p1 => { calendarAddress => 'mailto:a@example.com', participationStatus => 'needs-action', roles => { attendee => $T } },
    p2 => { calendarAddress => 'mailto:b@example.com', participationStatus => 'accepted', roles => { attendee => $T } },
  },
  recurrenceOverrides => {
    '2025-01-13T09:00:00' => { 'participants/p1/participationStatus' => 'accepted', title => 'Moved', start => '2025-01-13T11:00:00' },
    '2025-01-20T09:00:00' => { excluded => $T },
    '2025-01-27T09:00:00' => { 'participants/p2' => undef, uid => 'other', 'participants/p1/calendarAddress' => 'mailto:x@example.com' },
  },
};
my $before = JSON::XS->new->canonical->encode($master);

my $plain = $jscal->instance($master, '2025-01-06T09:00:00');
is($plain->{recurrenceId}, '2025-01-06T09:00:00', 'instance: recurrenceId is set');
is($plain->{recurrenceIdTimeZone}, 'Europe/Berlin', '... and recurrenceIdTimeZone, the master\'s timeZone');
is($plain->{start}, '2025-01-06T09:00:00', '... start is the recurrence id');
ok(!exists $plain->{recurrenceRule} && !exists $plain->{recurrenceOverrides}, '... without rule or overrides');

my $moved = Text::JSCalendar->instance($master, '2025-01-13T09:00:00');
is($moved->{start}, '2025-01-13T11:00:00', 'a patched start moves the instance');
is($moved->{title}, 'Moved', '... other properties are patched');
is($moved->{participants}{p1}{participationStatus}, 'accepted', '... so is a pointer path into a participant');
is($moved->{participants}{p2}{participationStatus}, 'accepted', '... which leaves the rest alone');

is($jscal->instance($master, '2025-01-20T09:00:00'), undef, 'an excluded instance is undef');

my $other = $jscal->instance($master, '2025-01-27T09:00:00');
ok(!exists $other->{participants}{p2}, 'a null patch removes');
is($other->{uid}, 'm@example.com', 'a patch cannot change the uid');
is($other->{participants}{p1}{calendarAddress}, 'mailto:a@example.com', '... or a participant\'s calendarAddress');

is(JSON::XS->new->canonical->encode($master), $before, 'instance leaves the master alone');

my $first = $jscal->instance($sm, '2025-03-12T09:00:00');
ok(!exists $first->{Text::JSCalendar::SYNTHETIC_MASTER()}, 'an instance of a synthetic master is not marked');
is($first->{start}, '2025-03-12T10:00:00', '... and starts where the instance does');
is($jscal->instance($sm, '2025-03-26T09:00:00'), undef, '... and is undef for an id that is not one of its instances');

done_testing;
