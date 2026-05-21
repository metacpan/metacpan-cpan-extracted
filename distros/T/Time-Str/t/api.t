#!perl
use strict;
use warnings;

use Test::More;

use lib 't';
use Util qw[throws_ok];

BEGIN {
  use_ok('Time::Str', qw[str2time str2date time2str]);
}

diag('Test::Str IMPLEMENTATION: ', Time::Str::IMPLEMENTATION);

# str2date usage
throws_ok { str2date() }
  qr/^Usage: str2date/,
  'str2date: no arguments';

throws_ok { str2date('2012-12-24T15:30:45Z', 'extra') }
  qr/^Usage: str2date/,
  'str2date: even number of arguments';

# str2date parameter 'format'
throws_ok { str2date('2012-12-24', format => 'NOSUCH') }
  qr/Parameter 'format' is unknown: 'NOSUCH'/,
  'str2date: unknown format';

# str2date parameter 'pivot_year'
throws_ok { str2date('121224153045Z', format => 'ASN1UT', pivot_year => -1) }
  qr/Parameter 'pivot_year' is out of range/,
  'str2date: pivot_year too low';

throws_ok { str2date('121224153045Z', format => 'ASN1UT', pivot_year => 9900) }
  qr/Parameter 'pivot_year' is out of range/,
  'str2date: pivot_year too high';

# str2date unknown named parameter
throws_ok { str2date('2012-12-24T15:30:45Z', color => 'red') }
  qr/Unrecognised named parameter: 'color'/,
  'str2date: unknown named parameter';

# str2date parse failure
throws_ok { str2date('not-a-date') }
  qr/Unable to parse: string does not match the RFC 3339 format/,
  'str2date: parse failure (default format)';

throws_ok { str2date('not-a-date', format => 'RFC2822') }
  qr/Unable to parse: string does not match the RFC 2822 format/,
  'str2date: parse failure (explicit format)';

# str2date date out of range
throws_ok { str2date('2012-13-24T15:30:45Z') }
  qr/Unable to parse: month is invalid/,
  'str2date: month 13';

throws_ok { str2date('2012-00-24T15:30:45Z') }
  qr/Unable to parse: month is invalid/,
  'str2date: month 0';

throws_ok { str2date('2013-02-29T15:30:45Z') }
  qr/Unable to parse: date is out of range/,
  'str2date: Feb 29 in non-leap year';

# str2date time of day out of range
throws_ok { str2date('2012-12-24T24:00:00Z') }
  qr/Unable to parse: time of day is out of range/,
  'str2date: hour 24';

throws_ok { str2date('2012-12-24T12:60:00Z') }
  qr/Unable to parse: time of day is out of range/,
  'str2date: minute 60';

throws_ok { str2date('2012-12-24T23:59:61Z') }
  qr/Unable to parse: time of day is out of range/,
  'str2date: second 61';

# str2date timezone offset out of range
throws_ok { str2date('2012-12-24T15:30:45+25:00') }
  qr/Unable to parse: timezone offset is invalid/,
  'str2date: timezone offset hour out of range';

# str2time usage
throws_ok { str2time() }
  qr/^Usage: str2time/,
  'str2time: no arguments';

throws_ok { str2time('2012-12-24T15:30:45Z', 'extra') }
  qr/^Usage: str2time/,
  'str2time: even number of arguments';

# str2time parameter 'precision'
throws_ok { str2time('2012-12-24T15:30:45Z', precision => -1) }
  qr/Parameter 'precision' is out of range/,
  'str2time: precision too low';

throws_ok { str2time('2012-12-24T15:30:45Z', precision => 10) }
  qr/Parameter 'precision' is out of range/,
  'str2time: precision too high';

# str2time no timezone
throws_ok { str2time('2012-12-24 15:30:45', format => 'ISO9075') }
  qr/Unable to convert/,
  'str2time: no timezone offset or UTC designator';

# time2str usage
throws_ok { time2str() }
  qr/^Usage: time2str/,
  'time2str: no arguments';

throws_ok { time2str(0, 'extra') }
  qr/^Usage: time2str/,
  'time2str: even number of arguments';

# time2str parameter 'time'
throws_ok { time2str(Time::Str::MIN_TIME - 1) }
  qr/Parameter 'time' is out of range/,
  'time2str: time below minimum';

throws_ok { time2str(Time::Str::MAX_TIME + 1) }
  qr/Parameter 'time' is out of range/,
  'time2str: time above maximum';

# time2str parameter 'format'
throws_ok { time2str(0, format => 'NOSUCH') }
  qr/Parameter 'format' is unknown: 'NOSUCH'/,
  'time2str: unknown format';

# time2str parameter 'offset'
throws_ok { time2str(0, offset => -1440) }
  qr/Parameter 'offset' is out of range/,
  'time2str: offset too low';

throws_ok { time2str(0, offset => 1440) }
  qr/Parameter 'offset' is out of range/,
  'time2str: offset too high';

# time2str parameter 'precision'
throws_ok { time2str(0, precision => -1) }
  qr/Parameter 'precision' is out of range/,
  'time2str: precision too low';

throws_ok { time2str(0, precision => 10) }
  qr/Parameter 'precision' is out of range/,
  'time2str: precision too high';

# time2str parameter 'nanosecond'
throws_ok { time2str(0, nanosecond => -1) }
  qr/Parameter 'nanosecond' is out of range/,
  'time2str: nanosecond too low';

throws_ok { time2str(0, nanosecond => 1_000_000_000) }
  qr/Parameter 'nanosecond' is out of range/,
  'time2str: nanosecond too high';

# time2str unknown named parameter
throws_ok { time2str(0, color => 'red') }
  qr/Unrecognised named parameter: 'color'/,
  'time2str: unknown named parameter';

# time2str time out of range for given offset
throws_ok { time2str(Time::Str::MAX_TIME, offset => 1) }
  qr/Parameter 'time' is out of range for the given offset/,
  'time2str: time out of range for positive offset';

throws_ok { time2str(Time::Str::MIN_TIME, offset => -1) }
  qr/Parameter 'time' is out of range for the given offset/,
  'time2str: time out of range for negative offset';

done_testing();
