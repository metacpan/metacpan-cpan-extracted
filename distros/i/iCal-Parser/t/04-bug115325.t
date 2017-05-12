# -*-cperl -*-
# vim: ft=perl
# $Id$
use Test::More tests => 3;
use iCal::Parser;

# Test bug reported in https://rt.cpan.org/Public/Bug/Display.html?id=115325
# Because of operator priority, any value for DTSTART VALUE parameter will
# behave as 'DATE'. So here we set the only other possible value (DATE-TIME),
# which is also the default, and check that it returns the same as not
# specifying anything at all:

sub make_event {
  my $extra_param = shift // '';
  return <<EOC;
BEGIN:VCALENDAR
BEGIN:VEVENT
UID:test1
DTSTART$extra_param:20221201T130000Z
DTEND:20221201T150000Z
END:VEVENT
END:VCALENDAR
EOC
}

my $p = iCal::Parser->new(start=>'20221201', end=>'20221202');
my $date_time1 = make_event();
my $parsed1 = $p->parse_strings($date_time1);

$p = iCal::Parser->new(start=>'20221201', end=>'20221202');
my $date_time2 = make_event(';VALUE=DATE-TIME');
my $parsed2 = $p->parse_strings($date_time2);

is_deeply($parsed1, $parsed2, 'DATE-TIME same as no param');

# And both should not be 'all-day'
is($parsed1->{events}{2022}{12}{1}{test1}{allday}//0, 0,
   'no param: not a full day event');
is($parsed2->{events}{2022}{12}{1}{test1}{allday}//0, 0,
   'explicit DATE-TIME: still not a full day event');
