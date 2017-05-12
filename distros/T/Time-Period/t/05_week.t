use strict;
use warnings;

use Test::More tests => 20;
use Time::Period;

use POSIX;
my $base_date = POSIX::mktime(0, 0, 0, 1, 0, 111); # 01/01/2011 00:00:00 (Saturday)
my $week = 7 * 24 * 60 * 60;

is(inPeriod($base_date, 'wk {1}'), 1, 'should match a single week');
is(inPeriod($base_date, 'week {1}'), 1, 'should match a single week, by the long form');
is(inPeriod($base_date - $week, 'wk {1}'), 0, 'should be able to not match a single week');

is(inPeriod($base_date + $week, 'wk {1-3}'), 1, 'should be able to match a range of weeks');
is(inPeriod($base_date - $week, 'wk {1-3}'), 0, 'should be able to not match a range of weeks');

is(inPeriod($base_date - $week, 'wk {5-1}'), 0, 'should be able to not match a range of weeks when the first week is greater than the second');
is(inPeriod($base_date - $week, 'wk {3-2}'), 1, 'should be able to match a range of weeks when the first week is greater than the second');
is(inPeriod($base_date - $week, 'wk {5-4}'), 1, 'should be able to match a range of weeks when the first week is greater than the second');
is(inPeriod($base_date - $week, 'wk {5-6}'), 0, 'should be able to not match a range of weeks when the first week is less than the second');

is(inPeriod(1296450000, 'wk {6}'), 1, 'should be able to match the 6th week of a month');

is(inPeriod(0, 'wk {one}'), -1, 'should return -1 for non-numeric week numbers (single)');
is(inPeriod(0, 'wk {one - 3}'), -1, 'should return -1 for non-numeric week numbers (left)');
is(inPeriod(0, 'wk {3-one}'), -1, 'should return -1 for non-numeric week numbers (right)');

is(inPeriod(0, 'wk {0}'), -1, 'should return -1 for week numbers less than 1 (single)');
is(inPeriod(0, 'wk {0-3}'), -1, 'should return -1 for week numbers less than 1 (left)');
is(inPeriod(0, 'wk {3-0}'), -1, 'should return -1 for week numbers less than 1 (right)');

is(inPeriod(0, 'wk {7}'), -1, 'should return -1 for week numbers greater than 6 (single)');
is(inPeriod(0, 'wk {7-1}'), -1, 'should return -1 for week numbers greater than 6 (left)');
is(inPeriod(0, 'wk {1-7}'), -1, 'should return -1 for week numbers greater than 6 (right)');

my $sunday = POSIX::mktime(0, 0, 12, 8, 5, 114); # 01/01/2011 00:00:00 (Saturday)
is(inPeriod($sunday, 'wk { 2 }'), 1, 'should be able to match the week when the day is Sunday');
