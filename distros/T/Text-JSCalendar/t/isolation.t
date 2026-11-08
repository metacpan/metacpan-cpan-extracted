#!perl -T
use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More;
use Text::JSCalendar;

# One bad component costs only itself: the reader converts each VEVENT or
# VTODO, and each VALARM and RRULE in it, on its own; the writer each
# object and each alert.  What was dropped is reported by errors().

my $jscal = Text::JSCalendar->new();

sub ics { join("\r\n", 'BEGIN:VCALENDAR', 'VERSION:2.0', 'PRODID:x', @_, 'END:VCALENDAR', '') }
sub vevent {
  my ($uid, @props) = @_;
  return ('BEGIN:VEVENT', "UID:$uid", 'DTSTAMP:20250101T000000Z', @props, 'END:VEVENT');
}

# --- reading

{
  my @e = $jscal->vcalendarToEvents(ics(
    vevent('good@example.com', 'DTSTART:20250101T100000Z'),
    vevent('bad@example.com', 'DTSTART:20250101T100000Z', 'RRULE:FREQ=FORTNIGHTLY'),
  ));
  is_deeply([map { $_->{uid} } @e], ['bad@example.com', 'good@example.com'], 'a bad RRULE keeps its event');
  ok(!exists $e[0]{recurrenceRule}, '... without the rule');
  my @err = $jscal->errors;
  is(scalar @err, 1, 'one error');
  is($err[0]{uid}, 'bad@example.com', '... for the event');
  is($err[0]{component}, 'RRULE', '... naming the RRULE');
  like($err[0]{message}, qr/FREQ \(fortnightly\)/, '... and why');
  unlike($err[0]{message}, qr/\n| line \d+/, '... in one line, without a location');
}

{
  my @e = $jscal->vcalendarToEvents(ics(
    vevent('alarms@example.com', 'DTSTART:20250101T100000Z',
      'BEGIN:VALARM', 'UID:no-action', 'TRIGGER:-PT5M', 'END:VALARM',
      'BEGIN:VALARM', 'UID:fine', 'ACTION:DISPLAY', 'TRIGGER:-PT10M', 'END:VALARM'),
  ));
  is(scalar @e, 1, 'a VALARM without ACTION keeps its event');
  is_deeply([sort keys %{$e[0]{alerts}}], ['fine'], '... and its other alarms');
  my @err = $jscal->errors;
  is_deeply([map { [$_->{uid}, $_->{component}, $_->{id}] } @err],
            [['alarms@example.com', 'VALARM', 'no-action']], '... and reports the alarm');
}

{
  my @e = $jscal->vcalendarToEvents(ics(
    vevent('nostart@example.com', 'SUMMARY:no DTSTART'),
    vevent('fine@example.com', 'DTSTART:20250101T100000Z'),
  ));
  is_deeply([map { $_->{uid} } @e], ['fine@example.com'], 'a VEVENT that cannot convert costs only itself');
  is_deeply([map { [$_->{uid}, $_->{component}] } $jscal->errors],
            [['nostart@example.com', 'VEVENT']], '... and is reported');

  $jscal->vcalendarToEvents(ics(vevent('fine@example.com', 'DTSTART:20250101T100000Z')));
  is_deeply([$jscal->errors], [], 'errors() is reset by the next call');
}

{
  my @e = eval { $jscal->vcalendarToEvents(ics(
    'BEGIN:VTODO', 'UID:t@example.com', 'DTSTAMP:20250101T000000Z', 'DTSTART:2025-01-01', 'END:VTODO',
  )) };
  is($@, '', 'a bad date does not die');
  is(scalar @e, 0, '... it drops its task');
  is(($jscal->errors)[0]{component}, 'VTODO', '... reported as a VTODO');
}

# --- writing

my %base = (
  '@type' => 'Event', updated => '2025-01-01T00:00:00Z',
  start => '2025-01-01T10:00:00', timeZone => 'Etc/UTC', duration => 'PT1H',
);

{
  my $ical = $jscal->eventsToVCalendar(
    { %base, uid => 'w-good@example.com', title => 'good' },
    { %base, uid => 'w-bad@example.com', title => 'bad', recurrenceRule => { frequency => 'fortnightly' } },
  );
  like($ical, qr/^UID:w-good\@example\.com/m, 'the writer writes the good event');
  unlike($ical, qr/w-bad/, '... and leaves out the bad one');
  is_deeply([map { [$_->{uid}, $_->{component}] } $jscal->errors],
            [['w-bad@example.com', 'Event']], '... reporting it');
  like(($jscal->errors)[0]{message}, qr/frequency \(fortnightly\)/, '... and why');
}

{
  my $ical = $jscal->eventsToVCalendar({ %base, uid => 'w-alerts@example.com', title => 'alerts',
    alerts => {
      a1 => { trigger => { '@type' => 'OffsetTrigger', offset => '-PT5M' } },
      a2 => { trigger => { '@type' => 'example.com:SpecialTrigger' } },
    },
  });
  like($ical, qr/^UID:a1/m, 'a bad alert keeps its event and the other alerts');
  unlike($ical, qr/^UID:a2/m, '... and is left out');
  is_deeply([map { [$_->{uid}, $_->{component}, $_->{id}] } $jscal->errors],
            [['w-alerts@example.com', 'Alert', 'a2']], '... reporting it');
}

{
  my $ical = $jscal->eventsToVCalendar('not an object', { %base, uid => 'w-ok@example.com' });
  like($ical, qr/^UID:w-ok\@example\.com/m, 'a non-object is skipped');
  is(scalar(my @e = $jscal->errors), 1, '... and reported');
  $jscal->eventsToVCalendar({ %base, uid => 'w-ok@example.com' });
  is_deeply([$jscal->errors], [], 'errors() is reset by the next write');
}

done_testing;
