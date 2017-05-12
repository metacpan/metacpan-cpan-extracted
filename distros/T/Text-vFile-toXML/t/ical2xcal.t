#!/usr/bin/perl -w

use strict;
use warnings;
use Test::More tests => 5;
use File::Temp qw(tempfile);

# Enable functional interface
use Text::vFile::toXML qw(to_xml);

# Input filename
my ($fh, $fname) = tempfile;
print $fh <<'HF0';
BEGIN:VCALENDAR
PRODID:-//Google Inc//Google Calendar 70.9054//EN
VERSION:2.0
CALSCALE:GREGORIAN
METHOD:PUBLISH
X-WR-CALNAME:tester
X-WR-TIMEZONE:America/Chicago
X-WR-CALDESC:test0
BEGIN:VTIMEZONE
TZID:America/Chicago
X-LIC-LOCATION:America/Chicago
BEGIN:STANDARD
TZOFFSETFROM:-0500
TZOFFSETTO:-0600
TZNAME:CST
DTSTART:19701025T020000
RRULE:FREQ=YEARLY;BYMONTH=10;BYDAY=-1SU
END:STANDARD
BEGIN:DAYLIGHT
TZOFFSETFROM:-0600
TZOFFSETTO:-0500
TZNAME:CDT
DTSTART:19700405T020000
RRULE:FREQ=YEARLY;BYMONTH=4;BYDAY=1SU
END:DAYLIGHT
END:VTIMEZONE
BEGIN:VEVENT
DTSTART;TZID=America/Chicago:20061207T103000
DTEND;TZID=America/Chicago:20061207T130000
DTSTAMP:20061221T044747Z
ORGANIZER;CN=tester:MAILTO:9ulj23g1182hh29e1hscju9cff@group.calendar.google
 .com
UID:ojogh05rhp8aspkeeqqah5cf20@google.com
CLASS:PRIVATE
CREATED:20061221T044712Z
LAST-MODIFIED:20061221T044712Z
SEQUENCE:0
STATUS:CONFIRMED
SUMMARY;LANGUAGE=en-uk:test1
TRANSP:OPAQUE
END:VEVENT
BEGIN:VEVENT
DTSTART;TZID=America/Chicago:20061205T130000
DTEND;TZID=America/Chicago:20061205T153000
DTSTAMP:20061221T044747Z
ORGANIZER;CN=tester:MAILTO:9ulj23g1182hh29e1hscju9cff@group.calendar.google
 .com
UID:4n9g4k4r8nkak058kseh7qi62o@google.com
CLASS:PRIVATE
CREATED:20061221T044708Z
LAST-MODIFIED:20061221T044708Z
SEQUENCE:0
STATUS:CONFIRMED
SUMMARY:aoweigawoeg
TRANSP:OPAQUE
END:VEVENT
BEGIN:VEVENT
DTSTART;TZID=America/Chicago:20061204T103000
DTEND;TZID=America/Chicago:20061204T130000
DTSTAMP:20061221T044747Z
ORGANIZER;CN=tester:MAILTO:9ulj23g1182hh29e1hscju9cff@group.calendar.google
 .com
UID:nh9cudd636c0njnn707tlcbdvo@google.com
CLASS:PRIVATE
CREATED:20061221T044704Z
LAST-MODIFIED:20061221T044704Z
SEQUENCE:0
STATUS:CONFIRMED
SUMMARY:test2
TRANSP:OPAQUE
END:VEVENT
END:VCALENDAR
HF0
seek $fh, 0, 0;

my $a = Text::vFile::toXML->new(filename => $fname)->to_xml;
my $b = Text::vFile::toXML->new(filehandle => $fh)->to_xml;

use Text::vFile::asData; # to make the functional example work
seek $fh, 0, 0;
my $data = Text::vFile::asData->new->parse($fh);

my $c = Text::vFile::toXML->new(data => $data)->to_xml;

# Use functional interface
my $d = to_xml($data);

# Now ($a, $b, $c, $d) all contain the same XML string.
# TODO: Check against precompiled string
my $check = <<'HF1';
<iCalendar xmlns:xCal='urn:ietf:params:xml:ns:xcal'><vcalendar><prodid>-//Google Inc//Google Calendar 70.9054//EN</prodid><x-wr-timezone>America/Chicago</x-wr-timezone><calscale>GREGORIAN</calscale><vevent><uid>ojogh05rhp8aspkeeqqah5cf20@google.com</uid><last-modified>20061221T044712Z</last-modified><sequence/><status>CONFIRMED</status><created>20061221T044712Z</created><organizer cn='tester'>MAILTO:9ulj23g1182hh29e1hscju9cff@group.calendar.google.com</organizer><summary xml:lang='en-uk'>test1</summary><dtend tzid='America/Chicago'>20061207T130000</dtend><dtstamp>20061221T044747Z</dtstamp><class>PRIVATE</class><dtstart tzid='America/Chicago'>20061207T103000</dtstart><transp>OPAQUE</transp></vevent><vevent><uid>4n9g4k4r8nkak058kseh7qi62o@google.com</uid><last-modified>20061221T044708Z</last-modified><sequence/><status>CONFIRMED</status><created>20061221T044708Z</created><organizer cn='tester'>MAILTO:9ulj23g1182hh29e1hscju9cff@group.calendar.google.com</organizer><summary>aoweigawoeg</summary><dtend tzid='America/Chicago'>20061205T153000</dtend><dtstamp>20061221T044747Z</dtstamp><class>PRIVATE</class><dtstart tzid='America/Chicago'>20061205T130000</dtstart><transp>OPAQUE</transp></vevent><vevent><uid>nh9cudd636c0njnn707tlcbdvo@google.com</uid><last-modified>20061221T044704Z</last-modified><sequence/><status>CONFIRMED</status><created>20061221T044704Z</created><organizer cn='tester'>MAILTO:9ulj23g1182hh29e1hscju9cff@group.calendar.google.com</organizer><summary>test2</summary><dtend tzid='America/Chicago'>20061204T130000</dtend><dtstamp>20061221T044747Z</dtstamp><class>PRIVATE</class><dtstart tzid='America/Chicago'>20061204T103000</dtstart><transp>OPAQUE</transp></vevent><x-wr-caldesc>test0</x-wr-caldesc><version>2.0</version><x-wr-calname>tester</x-wr-calname><method>PUBLISH</method><vtimezone><daylight><rrule>FREQ=YEARLY;BYMONTH=4;BYDAY=1SU</rrule><tzoffsetfrom>-0600</tzoffsetfrom><tzname>CDT</tzname><dtstart>19700405T020000</dtstart><tzoffsetto>-0500</tzoffsetto></daylight><standard><rrule>FREQ=YEARLY;BYMONTH=10;BYDAY=-1SU</rrule><tzoffsetfrom>-0500</tzoffsetfrom><tzname>CST</tzname><dtstart>19701025T020000</dtstart><tzoffsetto>-0600</tzoffsetto></standard><tzid>America/Chicago</tzid><x-lic-location>America/Chicago</x-lic-location></vtimezone></vcalendar></iCalendar>
HF1
chomp($check);
ok($a eq $check);
ok($b eq $check);
ok($c eq $check);
ok($d eq $check);

{
my $a = to_xml();
is($a, "<iCalendar xmlns:xCal='urn:ietf:params:xml:ns:xcal'/>", "Empty data in procedural use");
}

__END__

