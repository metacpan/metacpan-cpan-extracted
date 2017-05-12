# -*-cperl -*-
# $Id: 02parse.t 6 2005-03-20 00:35:17Z rick $
use Test::More tests => 1;
use iCal::Parser;

# test bug:
# Can't call method "year" on an undefined value at lib/iCal/Parser.pm line 298.
iCal::Parser->new(start=>'20040101')->parse_files(
    qw{ t/calendars/04recurrence.ics
        t/calendars/02event-end.ics
  });
ok(1, 'calendar w/o recurrence after one with');
