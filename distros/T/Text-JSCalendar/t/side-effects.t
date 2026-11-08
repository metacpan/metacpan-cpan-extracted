#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;

# Loading or using the module changes nothing outside it: no
# $SIG{__WARN__}, no globals in main::, no output on STDERR, and a
# warning from the caller's own code is still the caller's.

my @caught;
BEGIN { $SIG{__WARN__} = sub { push @caught, $_[0] } }
my $handler;
BEGIN { $handler = $SIG{__WARN__} }

use Text::JSCalendar;

is($SIG{__WARN__}, $handler, 'loading the module leaves $SIG{__WARN__} alone');

my $jscal = Text::JSCalendar->new();

sub ics { join("\r\n", 'BEGIN:VCALENDAR', 'VERSION:2.0', 'PRODID:x', @_, 'END:VCALENDAR', '') }

my @e = $jscal->vcalendarToEvents(ics(
  'BEGIN:VEVENT', 'UID:dup@example.com', 'DTSTAMP:20250101T000000Z',
  'DTSTART:20250101T100000Z', 'DTEND:20250101T110000Z', 'DURATION:PT2H',
  'ATTACH;FILENAME=agenda.pdf:https://example.com/agenda',
  'SEQUENCE:x', 'END:VEVENT',
  'BEGIN:VEVENT', 'UID:dup@example.com', 'DTSTAMP:20250101T000000Z',
  'DTSTART:20250108T100000Z', 'END:VEVENT',
));
is(scalar @e, 1, 'a duplicate UID is read as one event');
is_deeply(\@caught, [], 'reading writes no warning (it used to Dumper both events to STDERR)');
is_deeply([sort map { $_->{message} } $jscal->warnings], [
  'DTEND and DURATION cannot both be set; DURATION ignored',
  'a second component without RECURRENCE-ID; read as an instance at its DTSTART',
], '... warnings() reports both oddities instead');
is_deeply([$jscal->errors], [], '... and nothing was dropped');
ok(!exists $e[0]{sequence}, 'a SEQUENCE that is not a number is ignored');
is((values %{$e[0]{links}})[0]{contentType}, 'application/pdf', 'the content type comes from FILENAME');
ok(!defined $main::{MimeTypes}, '... without a global in main::');

my $ical = $jscal->eventsToVCalendar({
  '@type' => 'Event', uid => 'w@example.com', updated => '2025-01-01T00:00:00Z',
  start => '2025-01-01T10:00:00', timeZone => 'Europe/Berlin', color => 'red',
  virtualLocations => { v => { uri => 'https://video.example.com/' } },
  alerts => { a => { action => 'email', trigger => { offset => '-PT5M' } } },
});
like($ical, qr/^COLOR:red/m, 'the writer writes properties Data::ICal does not know');
is_deeply(\@caught, [], '... without a warning about them');
is_deeply([map { $_->{message} } $jscal->warnings], ['missing mandatory property attendee'],
  '... and an email alarm without attendee is a warnings() entry, not a carp');

warn "mine\n";
is_deeply(\@caught, ["mine\n"], "the caller's own warnings still reach its handler");

done_testing;
