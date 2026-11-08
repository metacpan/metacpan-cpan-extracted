#!perl -T
use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More;
use JSON::XS ();
use Text::JSCalendar;

# eventsToVCalendar never changes the objects it is given: not their
# structure, and not their numbers, which a pattern match or a join
# would turn into strings (so the caller's JSON would then say "2").

my $jscal = Text::JSCalendar->new();
my $JSON = JSON::XS->new->canonical;

sub event {
  return {
    '@type' => 'Event', uid => 'nums@example.com', updated => '2025-01-01T00:00:00Z', sequence => 3,
    title => 'numbers', start => '2025-01-06T09:00:00', timeZone => 'Europe/Berlin', duration => 'PT1H',
    priority => 5,
    recurrenceRule => {
      '@type' => 'RecurrenceRule', frequency => 'monthly', interval => 2, count => 10,
      byDay => [ { '@type' => 'NDay', day => 'mo', nthOfPeriod => 1 }, { day => 'fr', nthOfPeriod => -1 } ],
      byMonthDay => [1, -1], byYearDay => [100], byWeekNo => [2], byMonth => ['1', '6'],
      byHour => [9], byMinute => [0, 30], bySecond => [0], bySetPosition => [1, -1],
    },
    recurrenceOverrides => {
      '2025-03-03T09:00:00' => { title => 'moved', 'participants/p1/scheduleSequence' => 2 },
      '2025-05-05T09:00:00' => { excluded => JSON::XS::true },
    },
    links => { l1 => { href => 'https://example.com/a.pdf', size => 1234, contentType => 'application/pdf' } },
    participants => {
      p1 => { calendarAddress => 'mailto:a@example.com', roles => { attendee => JSON::XS::true },
              scheduleSequence => 1, expectReply => JSON::XS::true },
    },
    alerts => { a1 => { trigger => { '@type' => 'OffsetTrigger', offset => '-PT15M' } } },
  };
}

sub task {
  return {
    '@type' => 'Task', uid => 'task@example.com', updated => '2025-01-01T00:00:00Z',
    start => '2025-01-06T09:00:00', timeZone => 'Europe/Berlin', due => '2025-01-07T09:00:00',
    percentComplete => 40, priority => 1,
  };
}

for my $make (\&event, \&task) {
  my $in = $make->();
  my $before = $JSON->encode($in);
  my $ical = $jscal->eventsToVCalendar($in);
  is_deeply([$jscal->errors], [], "$in->{uid} is written");
  is_deeply($in, $make->(), "$in->{uid}: the input is deeply unchanged");
  is($JSON->encode($in), $before, "$in->{uid}: and still encodes with its numbers as numbers");
}

# _argsToVCalendar (which Net::CalDAVTalk calls) and several objects at once
my @in = (event(), task());
my $before = $JSON->encode(\@in);
$jscal->_argsToVCalendar(\@in);
is($JSON->encode(\@in), $before, '_argsToVCalendar leaves its input alone too');

like($JSON->encode(event()), qr/"interval":2\b/, '(the check would see a stringified number)');

done_testing;
