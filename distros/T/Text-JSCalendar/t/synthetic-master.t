#!perl -T
use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More;
use JSON::XS ();
use Text::JSCalendar;

# A master the reader makes up for stand-alone instances is marked, and
# the writer goes by that mark alone: it writes the instances of a
# marked master and every other object whole.

my $jscal = Text::JSCalendar->new();
my $FLAG = Text::JSCalendar::SYNTHETIC_MASTER;
is($FLAG, 'jscalendar.fastmail.com:syntheticMaster', 'the mark is a vendor-specific property');

sub ics { join("\r\n", 'BEGIN:VCALENDAR', 'VERSION:2.0', 'PRODID:x', @_, 'END:VCALENDAR', '') }

my $standalone = ics(
  'BEGIN:VEVENT', 'UID:inst@example.com', 'DTSTAMP:20250101T000000Z', 'SEQUENCE:1',
  'RECURRENCE-ID;TZID=Europe/Berlin:20250319T090000',
  'DTSTART;TZID=Europe/Berlin:20250319T093000', 'DURATION:PT1H', 'SUMMARY:second',
  'ORGANIZER:mailto:boss@example.com', 'END:VEVENT',
  'BEGIN:VEVENT', 'UID:inst@example.com', 'DTSTAMP:20250101T000000Z', 'SEQUENCE:1',
  'RECURRENCE-ID;TZID=Europe/Berlin:20250312T090000',
  'DTSTART;TZID=Europe/Berlin:20250312T090000', 'DURATION:PT1H', 'SUMMARY:first',
  'ORGANIZER:mailto:boss@example.com', 'END:VEVENT',
);

my ($e) = $jscal->vcalendarToEvents($standalone);
ok($e->{$FLAG}, 'stand-alone instances get a marked master');
ok(Text::JSCalendar->isSyntheticMaster($e), '... isSyntheticMaster says so');
ok($jscal->isSyntheticMaster($e), '... called on an object too');
is($e->{start}, '2025-03-12T09:00:00', '... started at the earliest instance, whatever the component order');
is_deeply([sort keys %{$e->{recurrenceOverrides}}], ['2025-03-12T09:00:00', '2025-03-19T09:00:00'],
  '... with every instance an override');
ok(!grep({ exists $_->{$FLAG} } values %{$e->{recurrenceOverrides}}), '... and no patch touches the mark');

my $ical = $jscal->eventsToVCalendar($e);
is(scalar(() = $ical =~ /^BEGIN:VEVENT/mg), 2, 'the writer writes the two instances');
is(scalar(() = $ical =~ /^RECURRENCE-ID/mg), 2, '... each with its RECURRENCE-ID, and no master');
unlike($ical, qr/syntheticMaster/i, '... and the mark is not written');
like($ical, qr/^DTSTART;TZID=Europe\/Berlin:20250319T093000/m, '... keeping a moved instance where it was');

my ($again) = $jscal->vcalendarToEvents($ical);
is(JSON::XS->new->canonical->encode($again), JSON::XS->new->canonical->encode($e), 'which reads back the same');

# an excluded instance of a synthetic master has nowhere to go
{
  my %copy = %$e;
  $copy{recurrenceOverrides} = { %{$e->{recurrenceOverrides}}, '2025-03-19T09:00:00' => { excluded => JSON::XS::true } };
  my $out = $jscal->eventsToVCalendar(\%copy);
  is(scalar(() = $out =~ /^BEGIN:VEVENT/mg), 1, 'an excluded instance of a synthetic master is not written');
  unlike($out, qr/^EXDATE/m, '... not even as an EXDATE');
}

# a real event with an organizer and no participants is written: it used
# to be taken for a synthetic master and dropped
{
  my $real = {
    '@type' => 'Event', uid => 'orgonly@example.com', updated => '2025-01-01T00:00:00Z',
    title => 'Organizer only', start => '2025-03-10T09:00:00', timeZone => 'Europe/Berlin',
    duration => 'PT1H', organizerCalendarAddress => 'mailto:boss@example.com',
  };
  my $out = $jscal->eventsToVCalendar($real);
  like($out, qr/^UID:orgonly\@example\.com/m, 'an event with an organizer and no participants is written');
  my ($back) = $jscal->vcalendarToEvents($out);
  ok(!$jscal->isSyntheticMaster($back), '... and is not a synthetic master');
}

# a marked master with an override that patches nothing: still an instance
{
  my $m = {
    $FLAG => JSON::XS::true, '@type' => 'Event', uid => 'empty@example.com',
    updated => '2025-01-01T00:00:00Z', start => '2025-03-10T09:00:00', timeZone => 'Europe/Berlin',
    duration => 'PT1H', title => 'same',
    recurrenceOverrides => { '2025-03-10T09:00:00' => {} },
  };
  my $out = $jscal->eventsToVCalendar($m);
  like($out, qr/^RECURRENCE-ID;TZID=Europe\/Berlin:20250310T090000/m, 'an empty patch of a synthetic master is an instance');
  unlike($out, qr/^RDATE/m, '... not an RDATE');
  my ($back) = $jscal->vcalendarToEvents($out);
  is_deeply([keys %{$back->{recurrenceOverrides} || {}}], ['2025-03-10T09:00:00'], '... and reads back as one');
}

done_testing;
