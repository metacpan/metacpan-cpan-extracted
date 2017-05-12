# -*-cperl -*-
# vim: ft=perl
# $Id$
use Test::More tests => 1;
use iCal::Parser;

# Regression test:
# day() returns the day of month not the day in the calendar, therefore using
# int comparison will yield funny results when day-of-month of event end is
# before day-of-month of event start. This VCALENDAR, for instance, would have
# no event:

my $ical = <<EOC;
BEGIN:VCALENDAR
BEGIN:VEVENT
UID:test1
DTSTART:20221130T130000Z
DTEND:20221201T150000Z
END:VEVENT
END:VCALENDAR
EOC

my $p = iCal::Parser->new(start=>'20221201', end=>'20221202');
my $c =$p->parse_strings($ical);

ok(keys %{$c->{events}}, 'events are parsed despite day-of-month wrap');

