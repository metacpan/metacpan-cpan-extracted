use strict;
use warnings;

use Test::More tests => 23;

BEGIN { use_ok('Time::Period') };
can_ok(__PACKAGE__, 'inPeriod');

use POSIX;
my $base_date = POSIX::mktime(0, 0, 0, 1, 0, 111); # 01/01/2011 00:00:00 (Saturday)
my $day = 24 * 60 * 60;

is(inPeriod($base_date, 'wd {sa}'), 1, 'returns 1 for a match');
is(inPeriod($base_date, 'wd {fri-sun}'), 1, 'should be able to match ranges');
is(inPeriod($base_date + $day, 'wd {sa}'), 0, 'returns 0 for a non-match');
is(inPeriod('', 'wd {sa}'), -1, 'returns -1 when an empty string is passed for the time');
is(inPeriod('a', 'wd {sa}'), -1, 'returns -1 when time contains something other than a number');
is(inPeriod(0), 1, 'should always match an undefined period');
is(inPeriod(0, ''), 1, 'should always match an empty period');
is(inPeriod(0, 'none'), 0, 'should never match the period "none"');
is(inPeriod(0, 'wd {'), -1, 'should return -1 if there are more left braces than right ones');
is(inPeriod(0, 'wd }'), -1, 'should return -1 if there are more right braces than left ones');
is(inPeriod(0, 'wd'), -1, 'should return -1 if there aren\'t any braces');
is(inPeriod(0, '9{}'), -1, 'should return -1 for a numeric scale name');

is(inPeriod($base_date, 'wday {sa}'), 1, 'should match long-form names');
is(inPeriod($base_date, 'fooey {sa}'), -1, 'should return -1 for invalid long-form names');
is(inPeriod($base_date, 'fo {sa}'), -1, 'should return -1 for invalid short-form names');
is(inPeriod($base_date, 'f {sa}'), -1, 'should return -1 for single character names');

is(inPeriod(0, 'wd {%}'), -1, 'returns -1 if the range contains a non-alphanumeric character');
is(inPeriod(0, 'wd {%-9}'), -1, 'returns -1 if the range contains a non-alphanumeric character');
is(inPeriod(0, 'wd {9-%}'), -1, 'returns -1 if the range contains a non-alphanumeric character');

is(inPeriod($base_date, 'wd {sa} yr {2011}'), 1, 'should be able to match on multiple criteria');
is(inPeriod($base_date, 'wd {sa} yr {2010}'), 0, 'should be able to not match on multiple criteria');
