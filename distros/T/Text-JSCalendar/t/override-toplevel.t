#!perl -T
use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More;
use Text::JSCalendar;
use JSON::PP ();

plan tests => 20;

my $jscal = Text::JSCalendar->new();

# recurrenceOverrides patches must not change top-level-only properties
my $ical = $jscal->eventsToVCalendar({
  '@type'        => 'Event',
  uid            => 'master@example.com',
  title          => 'Standup',
  start          => '2025-06-01T10:00:00',
  duration       => 'PT30M',
  recurrenceRule => { frequency => 'daily', count => 3 },
  recurrenceOverrides => {
    '2025-06-02T10:00:00' => {
      uid            => 'other@example.com',
      title          => 'Moved standup',
      recurrenceRule => { frequency => 'weekly' },
    },
  },
});

my @uids = $ical =~ m/^UID:(.*?)\r?$/mg;
is_deeply(\@uids, ['master@example.com', 'master@example.com'], 'override cannot change uid');
unlike($ical, qr/other\@example\.com/, 'patched uid not emitted');
my @rrules = $ical =~ m/^(RRULE:.*?)\r?$/mg;
is(scalar(@rrules), 1, 'override cannot add recurrenceRule to exception');
like($ical, qr/^SUMMARY:Moved standup\r?$/m, 'other patches still applied');

# recurrenceOverrides patches must not change @type
my $ical2 = $jscal->eventsToVCalendar({
  '@type'        => 'Event',
  uid            => 'master2@example.com',
  title          => 'Weekly sync',
  start          => '2025-07-01T09:00:00',
  recurrenceRule => { frequency => 'weekly', count => 3 },
  recurrenceOverrides => {
    '2025-07-08T09:00:00' => { '@type' => 'Task', title => 'Changed' },
  },
});

unlike($ical2, qr/^BEGIN:VTODO/m, 'override cannot change @type');
my @vevents = $ical2 =~ m/^(BEGIN:VEVENT)/mg;
is(scalar(@vevents), 2, 'exception still emitted as VEVENT');
like($ical2, qr/^RECURRENCE-ID/m, 'exception has RECURRENCE-ID');

# an orphaned exception gets a synthetic master carrying @type
my ($orphan) = $jscal->vcalendarToEvents(join("\r\n",
  'BEGIN:VCALENDAR', 'VERSION:2.0', 'PRODID:test',
  'BEGIN:VEVENT', 'UID:orphan@example.com', 'DTSTAMP:20250101T000000Z',
  'RECURRENCE-ID:20250602T100000Z', 'DTSTART:20250602T110000Z', 'SUMMARY:x',
  'END:VEVENT', 'END:VCALENDAR', ''));
is($orphan->{'@type'}, 'Event', 'synthetic master has @type');
ok(!exists $orphan->{recurrenceOverrides}{'2025-06-02T10:00:00'}{'@type'}, 'no @type in override');

# privacy must match across recurrences, and attendee addresses are identity
my $ical3 = $jscal->eventsToVCalendar({
  '@type'        => 'Event',
  uid            => 'master3@example.com',
  title          => 'Planning',
  start          => '2025-08-01T09:00:00',
  recurrenceRule => { frequency => 'weekly', count => 3 },
  organizerCalendarAddress => 'mailto:org@example.com',
  participants   => {
    p1 => { '@type' => 'Participant', calendarAddress => 'mailto:org@example.com', roles => { owner => JSON::PP::true() } },
    p2 => { '@type' => 'Participant', calendarAddress => 'mailto:alice@example.com', roles => { attendee => JSON::PP::true() } },
  },
  recurrenceOverrides => {
    '2025-08-08T09:00:00' => {
      privacy                          => 'private',
      'participants/p2/calendarAddress' => 'mailto:mallory@example.com',
      title                            => 'Planning (moved)',
    },
  },
});

unlike($ical3, qr/^CLASS:/m, 'override cannot change privacy');
my @alice = $ical3 =~ m/^(ATTENDEE.*alice\@example\.com)/mg;
is(scalar(@alice), 2, 'attendee kept in both instances');
unlike($ical3, qr/mallory/, 'override cannot change participant calendarAddress');
like($ical3, qr/^SUMMARY:Planning \(moved\)\r?$/m, 'other patches still applied');

# RELATED-TO is allowed on exceptions (jscalendarbis-21), so keep it
my $relics = join("\r\n",
  'BEGIN:VCALENDAR', 'VERSION:2.0', 'PRODID:test',
  'BEGIN:VEVENT', 'UID:rel@example.com', 'DTSTAMP:20250101T000000Z',
  'DTSTART:20250601T100000Z', 'RRULE:FREQ=DAILY;COUNT=3', 'SUMMARY:x',
  'END:VEVENT',
  'BEGIN:VEVENT', 'UID:rel@example.com', 'DTSTAMP:20250101T000000Z',
  'RECURRENCE-ID:20250602T100000Z', 'DTSTART:20250602T100000Z', 'SUMMARY:x',
  'RELATED-TO:parent@example.com',
  'END:VEVENT', 'END:VCALENDAR', '');
my ($rel) = $jscal->vcalendarToEvents($relics);
ok(!$rel->{relatedTo}, 'master has no relatedTo');
ok($rel->{recurrenceOverrides}{'2025-06-02T10:00:00'}{relatedTo}{'parent@example.com'},
   'exception relatedTo kept as override');
my ($relback) = $jscal->vcalendarToEvents($jscal->eventsToVCalendar($rel));
is_deeply($relback->{recurrenceOverrides}, $rel->{recurrenceOverrides}, 'relatedTo override round-trips');

# a synthetic master carries version, so overrides don't
is($orphan->{version}, '2.0', 'synthetic master has version');
ok(!exists $orphan->{recurrenceOverrides}{'2025-06-02T10:00:00'}{version}, 'no version in override');

# a change inside a participant is a nested patch, and round-trips
my $att = 'ATTENDEE;CN=Alice;PARTSTAT=NEEDS-ACTION:mailto:alice@example.com';
my ($nested) = $jscal->vcalendarToEvents(join("\r\n",
  'BEGIN:VCALENDAR', 'VERSION:2.0', 'PRODID:test',
  'BEGIN:VEVENT', 'UID:nested@example.com', 'DTSTAMP:20250101T000000Z',
  'DTSTART:20250601T100000Z', 'RRULE:FREQ=DAILY;COUNT=3', 'SUMMARY:x', $att,
  'END:VEVENT',
  'BEGIN:VEVENT', 'UID:nested@example.com', 'DTSTAMP:20250101T000000Z',
  'RECURRENCE-ID:20250602T100000Z', 'DTSTART:20250602T100000Z', 'SUMMARY:x',
  ($att =~ s/NEEDS-ACTION/ACCEPTED/r),
  'END:VEVENT', 'END:VCALENDAR', ''));
my ($pid) = keys %{$nested->{participants}};
is_deeply($nested->{recurrenceOverrides}{'2025-06-02T10:00:00'},
  { "participants/$pid/participationStatus" => 'accepted' }, 'nested participant patch');
my ($nestedback) = $jscal->vcalendarToEvents($jscal->eventsToVCalendar($nested));
is_deeply($nestedback->{recurrenceOverrides}, $nested->{recurrenceOverrides}, 'nested patch round-trips');
