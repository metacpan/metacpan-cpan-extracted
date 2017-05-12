#!/usr/bin/env perl
use strict;
use warnings;

use lib '../../lib';

use Test::More tests => 31;

use_ok('XML::Loy::Date::RFC3339');

my $date = XML::Loy::Date::RFC3339->new(784111777);
is $date->to_string, '1994-11-06T08:49:37Z', 'right date';

$date = XML::Loy::Date::RFC3339->new('2011-07-30T16:30:00Z');
is($date, '2011-07-30T16:30:00Z', 'Date1');
is($date->epoch, 1312043400, 'Date2');

$date = XML::Loy::Date::RFC3339->new(1312043400);
is($date, '2011-07-30T16:30:00Z', 'Date3');
is($date->epoch, 1312043400, 'Date4');

# Offset
$date = XML::Loy::Date::RFC3339->new('1993-01-01t18:50:00-04:00');
is($date->to_string, '1993-01-01T22:50:00Z', 'right date');

# Offset
$date = XML::Loy::Date::RFC3339->new('1993-01-01t22:50:00-04:00');
is($date->to_string, '1993-01-02T02:50:00Z', 'right date');
is($date->epoch, '725943000', 'right epoch');

# Relaxed
$date = XML::Loy::Date::RFC3339->new('1993-1-1t18:50:0-4');
is($date->to_string, '1993-01-01T22:50:00Z', 'right date');

# Negative epoch value
# Different on perl 5.10.1 and perl 5.12 and later
# $date = XML::Loy::Date::RFC3339->new;
# ok($date->parse('1900-01-01T00:00:00Z'), 'right format 1');
# is($date->epoch, undef, 'no epoch value');

# Granularity 4
$date = XML::Loy::Date::RFC3339->new;
ok($date->parse('1993'), 'right format 2');
is($date->to_string, 1993, 'correct date value');
is($date->granularity, 4, 'correct granularity');

# Granularity 3
ok($date->parse('1993-11'), 'right format 3');
is($date->to_string, '1993-11', 'correct date value');
is($date->granularity, 3, 'correct granularity');

# Granularity 2
ok($date->parse('1993-11-3'), 'right format 4');
is($date->to_string, '1993-11-03', 'correct date value');
is($date->granularity, 2, 'correct granularity');

# Granularity 1
ok($date->parse('1993-11-3t19:20z'), 'right format 5');
is($date->to_string, '1993-11-03T19:20Z', 'correct date value');
is($date->granularity, 1, 'correct granularity');

# Underspecified
ok($date->parse('1993-11-3'), 'right format 6');
is($date->to_string(4), '1993', 'correct date value');
is($date->to_string(3), '1993-11', 'correct date value');
is($date->to_string(2), '1993-11-03', 'correct date value');
is($date->to_string(1), '1993-11-03T00:00Z', 'correct date value');
is($date->to_string(0), '1993-11-03T00:00:00Z', 'correct date value');

# Heavily underspecified
ok($date->parse('2002'), 'right format 7');
is($date->to_string, '2002', 'correct date value');
is($date->to_string(0), '2002-01-01T00:00:00Z', 'correct date value');

__END__

Year:
  YYYY (eg 1997)
Year and month:
  YYYY-MM (eg 1997-07)
Complete date:
  YYYY-MM-DD (eg 1997-07-16)
Complete date plus hours and minutes:
  YYYY-MM-DDThh:mmTZD (eg 1997-07-16T19:20+01:00)
Complete date plus hours, minutes and seconds:
  YYYY-MM-DDThh:mm:ssTZD (eg 1997-07-16T19:20:30+01:00)
Complete date plus hours, minutes, seconds
  and a decimal fraction of a second
  YYYY-MM-DDThh:mm:ss.sTZD (eg 1997-07-16T19:20:30.45+01:00)
