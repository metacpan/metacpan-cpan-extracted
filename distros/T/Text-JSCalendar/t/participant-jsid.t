#!perl -T
use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More;
use JSON::PP ();
use Digest::SHA qw(sha1_hex);
use Text::JSCalendar;

# jscalendar-icalendar 2.1.3, 2.3.4, 2.3.29: a participant's key travels in
# the JSID parameter of its ATTENDEE / ORGANIZER, and the reader MUST use it.

my $jscal = Text::JSCalendar->new();
my $true = JSON::PP::true();

sub unfold {
  my $ical = shift;
  $ical =~ s/\r?\n[ \t]//g;
  return $ical;
}

my $Event = {
  '@type'  => 'Event',
  uid      => 'jsid1@example.com',
  title    => 'Weekly',
  start    => '2025-06-02T10:00:00',
  timeZone => 'Etc/UTC',
  duration => 'PT1H',
  recurrenceRule => { '@type' => 'RecurrenceRule', frequency => 'weekly' },
  organizerCalendarAddress => 'mailto:org@example.com',
  participants => {
    o1 => { '@type' => 'Participant', calendarAddress => 'mailto:org@example.com',
            name => 'Org', roles => { owner => $true } },
    a1 => { '@type' => 'Participant', calendarAddress => 'mailto:alice@example.com',
            participationStatus => 'needs-action', roles => { attendee => $true } },
  },
  recurrenceOverrides => {
    '2025-06-09T10:00:00' => { 'participants/a1/participationStatus' => 'accepted' },
  },
};

my $ical = unfold($jscal->eventsToVCalendar($Event));
like($ical, qr/^ATTENDEE;[^\n]*JSID=a1[^\n]*:mailto:alice\@example\.com\r?$/m,
  'ATTENDEE carries the participant key');
like($ical, qr/^ORGANIZER;[^\n]*JSID=o1[^\n]*:mailto:org\@example\.com\r?$/m,
  'organizer-only participant key rides on ORGANIZER');
my @OverrideAttendees = $ical =~ m/^ATTENDEE;[^\n]*JSID=a1[^\n]*PARTSTAT=ACCEPTED/mg;
is(scalar @OverrideAttendees, 1, 'override ATTENDEE carries the same JSID');

my ($Back) = $jscal->vcalendarToEvents($ical);
is_deeply([sort keys %{$Back->{participants}}], ['a1', 'o1'], 'participant keys survive a round trip');
is($Back->{participants}{a1}{participationStatus}, 'needs-action', 'master partstat kept');
ok($Back->{participants}{o1}{roles}{owner}, 'organizer keyed by its JSID');
is_deeply($Back->{recurrenceOverrides},
  { '2025-06-09T10:00:00' => { 'participants/a1/participationStatus' => 'accepted' } },
  'override still patches participants/a1/participationStatus');

# an organizer that is also an ATTENDEE is still one participant
my ($Both) = $jscal->vcalendarToEvents(unfold($jscal->eventsToVCalendar({
  '@type'  => 'Event',
  uid      => 'jsid2@example.com',
  title    => 'x',
  start    => '2025-06-02T10:00:00',
  organizerCalendarAddress => 'mailto:org@example.com',
  participants => {
    me => { '@type' => 'Participant', calendarAddress => 'mailto:org@example.com',
            participationStatus => 'accepted', roles => { owner => $true, attendee => $true } },
  },
})));
is_deeply([keys %{$Both->{participants}}], ['me'], 'organizer and attendee merge under one JSID');
ok($Both->{participants}{me}{roles}{owner} && $Both->{participants}{me}{roles}{attendee},
  'merged participant has both roles');

# the key the reader would generate anyway needs no JSID
my $hash = sha1_hex('bob@example.com');
my $plain = unfold($jscal->eventsToVCalendar({
  '@type'  => 'Event',
  uid      => 'jsid3@example.com',
  title    => 'x',
  start    => '2025-06-02T10:00:00',
  participants => {
    $hash => { '@type' => 'Participant', calendarAddress => 'mailto:bob@example.com',
               roles => { attendee => $true } },
  },
}));
unlike($plain, qr/JSID/, 'no JSID when the key matches the default');
my ($Plain) = $jscal->vcalendarToEvents($plain);
is_deeply([keys %{$Plain->{participants}}], [$hash], 'default key round-trips');

# reading iCalendar written by someone else
my $ics = join("\r\n", 'BEGIN:VCALENDAR', 'VERSION:2.0', 'PRODID:test',
  'BEGIN:VEVENT', 'UID:jsid4@example.com', 'DTSTAMP:20250101T000000Z',
  'DTSTART:20250601T100000Z', 'SUMMARY:x',
  'ATTENDEE;JSID=p-1:mailto:one@example.com',
  'ATTENDEE;X-JMAP-ID=p2:mailto:two@example.com',
  'ATTENDEE;JSID="bad key":mailto:three@example.com',
  'ATTENDEE:mailto:four@example.com',
  'END:VEVENT', 'END:VCALENDAR', '');
my ($Read) = $jscal->vcalendarToEvents($ics);
is_deeply([sort keys %{$Read->{participants}}],
  [sort 'p-1', 'p2', sha1_hex('three@example.com'), sha1_hex('four@example.com')],
  'JSID, then X-JMAP-ID, then a hash of the address; an invalid Id is ignored');

done_testing();
