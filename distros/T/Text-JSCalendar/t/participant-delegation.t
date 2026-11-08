#!perl -T
use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More;
use JSON::PP ();
use Text::JSCalendar;

# jscalendarbis 4.4.5: delegatedTo/delegatedFrom are sets of calendar
# addresses; RFC 5545 3.2.4/3.2.5: each is a separately quoted cal-address.

my $jscal = Text::JSCalendar->new();
my $true = JSON::PP::true();

my $ical = $jscal->eventsToVCalendar({
  '@type'  => 'Event',
  uid      => 'deleg@example.com',
  title    => 'x',
  start    => '2025-06-02T10:00:00',
  participants => {
    a => { '@type' => 'Participant', calendarAddress => 'mailto:a@example.com',
           participationStatus => 'delegated',
           delegatedTo => { 'mailto:b@example.com' => $true, 'mailto:c@example.com' => $true } },
    b => { '@type' => 'Participant', calendarAddress => 'mailto:b@example.com',
           delegatedFrom => { 'mailto:a@example.com' => $true } },
  },
});
$ical =~ s/\r?\n[ \t]//g;
like($ical, qr/DELEGATED-TO="mailto:b\@example\.com","mailto:c\@example\.com"/,
  'each delegate is its own quoted value');

my ($e) = $jscal->vcalendarToEvents($ical);
is_deeply([sort keys %{$e->{participants}{a}{delegatedTo}}],
  ['mailto:b@example.com', 'mailto:c@example.com'], 'delegatedTo round-trips');
is_deeply([keys %{$e->{participants}{b}{delegatedFrom}}],
  ['mailto:a@example.com'], 'delegatedFrom round-trips');

# what the old writer produced: both addresses in one quoted value
my $ics = join("\r\n", 'BEGIN:VCALENDAR', 'VERSION:2.0', 'PRODID:test',
  'BEGIN:VEVENT', 'UID:deleg2@example.com', 'DTSTAMP:20250101T000000Z',
  'DTSTART:20250601T100000Z', 'SUMMARY:x',
  'ATTENDEE;DELEGATED-TO="mailto:b@example.com,mailto:c@example.com":mailto:a@example.com',
  'END:VEVENT', 'END:VCALENDAR', '');
my ($old) = $jscal->vcalendarToEvents($ics);
is_deeply([sort keys %{(values %{$old->{participants}})[0]{delegatedTo}}],
  ['mailto:b@example.com', 'mailto:c@example.com'], 'comma-joined delegates are split');

done_testing();
