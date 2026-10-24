#!perl -T
use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More;
use JSON::PP ();
use Text::JSCalendar;

plan tests => 6;

my $jscal = Text::JSCalendar->new();
my $true = JSON::PP::true();

sub attendees {
  my $ical = shift;
  $ical =~ s/\r?\n[ \t]//g;
  return sort map { m/:(mailto:\S+?)\r?$/i ? lc $1 : () } grep { /^ATTENDEE/ } split /\n/, $ical;
}

# jscalendarbis participants have no "attendee" role
my $ical = $jscal->eventsToVCalendar({
  '@type'  => 'Event',
  uid      => 'p1@example.com',
  title    => 'Meeting',
  start    => '2025-06-01T10:00:00',
  organizerCalendarAddress => 'mailto:org@example.com',
  participants => {
    org   => { '@type' => 'Participant', calendarAddress => 'mailto:org@example.com',
               name => 'Org', roles => { owner => $true } },
    alice => { '@type' => 'Participant', calendarAddress => 'mailto:alice@example.com',
               participationStatus => 'accepted' },
    bob   => { '@type' => 'Participant', calendarAddress => 'mailto:bob@example.com',
               roles => { optional => $true } },
  },
});
is_deeply([attendees($ical)], ['mailto:alice@example.com', 'mailto:bob@example.com'],
  'participants without attendee role become ATTENDEEs; organizer-only does not');
like($ical, qr/^ORGANIZER;CN=Org:mailto:org\@example\.com\r?$/m, 'organizer still written');
like($ical, qr/^ATTENDEE;[^\n]*ROLE=OPT-PARTICIPANT[^\n]*:mailto:bob/m, 'optional role kept');

# an organizer who has replied is also an ATTENDEE
my $ical2 = $jscal->eventsToVCalendar({
  '@type'  => 'Event',
  uid      => 'p2@example.com',
  title    => 'Meeting',
  start    => '2025-06-01T10:00:00',
  organizerCalendarAddress => 'mailto:org@example.com',
  participants => {
    org => { '@type' => 'Participant', calendarAddress => 'mailto:org@example.com',
             participationStatus => 'accepted', roles => { owner => $true } },
  },
});
is_deeply([attendees($ical2)], ['mailto:org@example.com'], 'organizer with PARTSTAT is also an ATTENDEE');

# legacy JSCalendar 1.0 "attendee" role is still honoured
my $ical3 = $jscal->eventsToVCalendar({
  '@type'  => 'Event',
  uid      => 'p3@example.com',
  title    => 'Meeting',
  start    => '2025-06-01T10:00:00',
  organizerCalendarAddress => 'mailto:org@example.com',
  participants => {
    org => { email => 'org@example.com', roles => { owner => $true, attendee => $true } },
  },
});
is_deeply([attendees($ical3)], ['mailto:org@example.com'], 'legacy attendee role');

# round trip of parsed iCalendar is unchanged
my $ics = join("\r\n", 'BEGIN:VCALENDAR', 'VERSION:2.0', 'PRODID:test',
  'BEGIN:VEVENT', 'UID:p4@example.com', 'DTSTAMP:20250101T000000Z',
  'DTSTART:20250601T100000Z', 'SUMMARY:x',
  'ORGANIZER;CN=Org:mailto:org@example.com',
  'ATTENDEE;PARTSTAT=ACCEPTED:mailto:alice@example.com',
  'END:VEVENT', 'END:VCALENDAR', '');
my ($e) = $jscal->vcalendarToEvents($ics);
is_deeply([attendees($jscal->eventsToVCalendar($e))], ['mailto:alice@example.com'],
  'parsed organizer-only participant does not gain an ATTENDEE');
