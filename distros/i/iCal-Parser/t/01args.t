# -*-cperl -*-
# $Id$
use Test::More tests => 6;
use iCal::Parser;
use DateTime;
use DateTime::Span;

require "t/Defrost.pm";

my $start=DateTime->new(year=>2004,month=>12,day=>01);
my $end=DateTime->new(year=>2005,month=>12,day=>01);
my $span=DateTime::Span->new(start=>$start, end=>$end);
my $tz='UTC';
my $h;
$VAR1=defrost("t/calendars/t-start.ics.dump");
$h=iCal::Parser->new(start=>'20041201',tz=>$tz)->parse('t/calendars/t.ics');
is_deeply($h,$VAR1,"start");

$h=iCal::Parser->new(start=>$start,tz=>$tz)->parse('t/calendars/t.ics');
is_deeply($h,$VAR1,"start as datetime");

$VAR1=defrost("t/calendars/t-start-end.ics.dump");
$h=iCal::Parser->new(start=>'20041201',end=>'20051201',tz=>$tz)
->parse('t/calendars/t.ics');
is_deeply($h,$VAR1,"start and end");

$h=iCal::Parser->new(start=>$start,end=>$end,tz=>$tz)
->parse('t/calendars/t.ics');
is_deeply($h,$VAR1,"start and end as datetimes");

$h=iCal::Parser->new(span=>$span,tz=>$tz)->parse('t/calendars/t.ics');
is_deeply($h,$VAR1,"span");

$VAR1=defrost("t/calendars/t-months.ics.dump");
$h=iCal::Parser->new(start=>'20040101',months=>14,tz=>$tz)
->parse('t/calendars/t.ics');
is_deeply($h,$VAR1,"months");
