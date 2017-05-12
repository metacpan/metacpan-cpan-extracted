use strict;
use warnings;

use Test::More tests => 18;
use Time::Period;

use POSIX;
my $base_date = POSIX::mktime(0, 0, 0, 1, 0, 111); # 01/01/2011 00:00:00 (Saturday)
my $day = 24 * 60 * 60;

is(inPeriod($base_date, 'md {1}'), 1, 'should match a single day');
is(inPeriod($base_date, 'mday {1}'), 1, 'should match a single day, by the long form');
is(inPeriod($base_date - $day, 'md {1}'), 0, 'should be able to not match a single day');

is(inPeriod($base_date + $day, 'md {1-3}'), 1, 'should be able to match a range of days');
is(inPeriod($base_date - $day, 'md {1-3}'), 0, 'should be able to not match a range of days');

is(inPeriod($base_date, 'md {31-5}'), 1, 'should be able to match a range of days when the first month day is greater than the second');
is(inPeriod($base_date - $day, 'md {31-5}'), 1, 'should be able to match a range of days when the first month day is greater than the second');
is(inPeriod($base_date - $day * 20, 'md {31-5}'), 0, 'should be able to not match a range of days when the first month day is greater than the second');

is(inPeriod($base_date + $day * 5, 'md {1-2}'), 0, 'should be able to not match a range of days when the first month day is less than the second');

is(inPeriod(0, 'md {one}'), -1, 'should return -1 for non-numeric day numbers (single)');
is(inPeriod(0, 'md {one - 3}'), -1, 'should return -1 for non-numeric day numbers (left)');
is(inPeriod(0, 'md {3-one}'), -1, 'should return -1 for non-numeric day numbers (right)');

is(inPeriod(0, 'md {0}'), -1, 'should return -1 for day numbers less than 1 (single)');
is(inPeriod(0, 'md {0-3}'), -1, 'should return -1 for day numbers less than 1 (left)');
is(inPeriod(0, 'md {3-0}'), -1, 'should return -1 for day numbers less than 1 (right)');

is(inPeriod(0, 'md {32}'), -1, 'should return -1 for day numbers greater than 31 (single)');
is(inPeriod(0, 'md {32-1}'), -1, 'should return -1 for day numbers greater than 31 (left)');
is(inPeriod(0, 'md {1-32}'), -1, 'should return -1 for day numbers greater than 31 (right)');
