use strict;
use warnings;

use Test::More tests => 27;
use Time::Period;

use POSIX;
my $base_date = POSIX::mktime(0, 0, 0, 1, 0, 111); # 01/01/2011 00:00:00 (Saturday)
my $day = 24 * 60 * 60;

is(inPeriod($base_date, 'wd {sa}'), 1, 'should match a single day');
is(inPeriod($base_date + $day, 'wd {sa}'), 0, 'should be able to not match a single day');

is(inPeriod($base_date, 'wd {fri-sun}'), 1, 'should be able to match a range of days');
is(inPeriod($base_date, 'wd {fri-sun}'), 1, 'should be able to not match a range of days');

is(inPeriod($base_date - $day, 'wd {sa-mon}'), 0, 'should be able to not match a range when the first weekday comes after the second');
is(inPeriod($base_date - $day, 'wd {sa-fr}'), 1, 'should "wrap around" to match ranges');

is(inPeriod($base_date - $day * 2, 'wd {fri-sat}'), 0, 'should be able to not match a range when the first weekday comes before the second');
is(inPeriod($base_date, 'wd {mon-fri}'), 0, 'should be able to not match a range when the first weekday comes before the second');

is(inPeriod($base_date, 'wd {saturday}'), 1, 'should allow long day names (single)');
is(inPeriod($base_date, 'wd {foobar}'), -1, 'should return -1 for invalid day names (single)');
is(inPeriod($base_date, 'wd {7}'), 1, 'should allow numeric days (single)');
is(inPeriod($base_date, 'wd {17}'), -1, 'should return -1 for numeric days greater than 7 (single)');
is(inPeriod($base_date, 'wd {0}'), -1, 'should return -1 for numeric days less than 1 (single)');
is(inPeriod($base_date, 'wd {_}'), -1, 'should return -1 for non-alphanumeric days (single)');

is(inPeriod($base_date, 'wd {saturday - su}'), 1, 'should allow long day names (left)');
is(inPeriod($base_date, 'wd {foobar - su}'), -1, 'should return -1 for invalid day names (left)');
is(inPeriod($base_date, 'wd {7 - su}'), 1, 'should allow numeric days (left)');
is(inPeriod($base_date, 'wd {17 - su}'), -1, 'should return -1 for numeric days greater than 7 (left)');
is(inPeriod($base_date, 'wd {0 - su}'), -1, 'should return -1 for numeric days less than 1 (left)');
is(inPeriod($base_date, 'wd {_ - su}'), -1, 'should return -1 for non-alphanumeric days (left)');

is(inPeriod($base_date, 'wd {fr - saturday}'), 1, 'should allow long day names (right)');
is(inPeriod($base_date, 'wd {fr - foobar}'), -1, 'should return -1 for invalid day names (right)');
is(inPeriod($base_date, 'wd {6 - 7}'), 1, 'should allow numeric days (right)');
is(inPeriod($base_date, 'wd {6 - 17}'), -1, 'should return -1 for numeric days greater than 7 (right)');
is(inPeriod($base_date, 'wd {1 - 0}'), -1, 'should return -1 for numeric days less than 1 (right)');
is(inPeriod($base_date, 'wd {6 - _}'), -1, 'should return -1 for non-alphanumeric days (right)');

my $sunday = $base_date + $day;
is(inPeriod($sunday, 'wd {sunday}'), 1, 'should work for Sundays');
