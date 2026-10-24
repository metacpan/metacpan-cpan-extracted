#!perl -T
use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More;
use JSON::PP ();
use Text::JSCalendar;

my $jscal = Text::JSCalendar->new();
my $true = JSON::PP::true();
my $evil = "x\r\nX-INJECTED:1\rY\nZ\x00\"";

my $ical = $jscal->eventsToVCalendar({
  '@type'  => 'Event',
  uid      => 'inject@example.com',
  title    => $evil,
  description => "line one\r\nline two\rX-INJECTED:1",
  descriptionContentType => "text/html$evil",
  locale   => "en$evil",
  start    => '2025-06-01T10:00:00',
  duration => 'PT1H',
  organizerCalendarAddress => 'mailto:org@example.com',
  participants => {
    p1 => {
      '@type'             => 'Participant',
      name                => "Alice$evil",
      calendarAddress     => 'mailto:alice@example.com',
      kind                => "individual$evil",
      participationStatus => "accepted$evil",
      scheduleAgent       => "server$evil",
      scheduleSequence    => "1$evil",
      roles               => { attendee => $true },
    },
  },
  links => {
    l1 => { '@type' => 'Link', href => 'https://example.com/a', rel => 'enclosure',
            title => "a.txt$evil", contentType => "text/plain$evil" },
  },
  virtualLocations => {
    "v1$evil" => { '@type' => 'VirtualLocation', uri => 'https://example.com/v',
                   name => "Room$evil", features => { "audio$evil" => $true } },
  },
  relatedTo => {
    'other@example.com' => { '@type' => 'Relation', relation => { "next$evil" => $true } },
  },
});

my @lines = split /\r\n/, $ical, -1;
my @bad = grep { /[\x00-\x08\x0a-\x1f\x7f]/ } @lines;
is_deeply(\@bad, [], 'no control characters left inside any content line');
my @injected = grep { /^X-INJECTED/i } @lines;
is_deeply(\@injected, [], 'no injected content lines');
is($lines[-1], '', 'output ends with CRLF');

# unfold, then check the description's newlines survive as escapes
(my $unfolded = $ical) =~ s/\r\n[ \t]//g;
like($unfolded, qr/^STYLED-DESCRIPTION;[^\r\n]*":line one\\nline two\\nX-INJECTED:1\r$/m,
  'newlines in values are escaped, a lone CR included');
like($unfolded, qr/^ATTENDEE;[^\r\n]*CN="?Alicex X-INJECTED:1 Y Z"?[;:]/m,
  'CR/LF in a parameter becomes a space');

done_testing();
