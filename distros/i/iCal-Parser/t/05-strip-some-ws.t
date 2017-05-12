# -*-cperl -*-
# vim: ft=perl
# $Id$
use Test::More tests => 1;
use iCal::Parser;

# Some iCal exporter add some whitespaces before the newline:

my $cal = <<EOC;
BEGIN:VCALENDAR
BEGIN:VEVENT
UID:test1
DTSTART:20221201T130000Z 
DTEND:20221201T150000Z
END:VEVENT
END:VCALENDAR
EOC

my $p = iCal::Parser->new(start=>'20221201', end=>'20221202');
my $c = $p->parse_strings($cal);

ok($c->{events}{2022}{12}{1}{test1}{DTSTART},
   'must parse despite trailing whitespace');
