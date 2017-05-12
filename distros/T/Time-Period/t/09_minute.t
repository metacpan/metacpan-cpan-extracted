use strict;
use warnings;

use Test::More tests => 15;
use Time::Period;

use POSIX;
my $base_date = POSIX::mktime(0, 0, 0, 1, 0, 111); # 01/01/2011 00:00:00 (Saturday)
my $minute = 60;

is(inPeriod($base_date, 'min {0}'), 1, 'should match a single minute');
is(inPeriod($base_date, 'minute {0}'), 1, 'should match a single minute, by the long form');
is(inPeriod($base_date - $minute, 'min {0}'), 0, 'should be able to not match a single minute');

is(inPeriod($base_date + $minute, 'min {0-3}'), 1, 'should be able to match a range of minutes');
is(inPeriod($base_date - $minute, 'min {0-3}'), 0, 'should be able to not match a range of minutes');

is(inPeriod($base_date, 'min {59-5}'), 1, 'should be able to match a range of days when the first minute is greater than the second');
is(inPeriod($base_date - $minute, 'min {59-5}'), 1, 'should be able to match a range of days when the first minute is greater than the second');
is(inPeriod($base_date - $minute * 20, 'min {59-5}'), 0, 'should be able to not match a range of days when the first minute is greater than the second');

is(inPeriod($base_date + $minute * 5, 'min {1-2}'), 0, 'should be able to not match a range of days when the first minute is less than the second');

is(inPeriod(0, 'min {one}'), -1, 'should return -1 for non-numeric minutes (single)');
is(inPeriod(0, 'min {one - 3}'), -1, 'should return -1 for non-numeric minutes (left)');
is(inPeriod(0, 'min {3-one}'), -1, 'should return -1 for non-numeric minutes (right)');

is(inPeriod(0, 'min {60}'), -1, 'should return -1 for minutes greater than 59 (single)');
is(inPeriod(0, 'min {60-1}'), -1, 'should return -1 for minutes greater than 59 (left)');
is(inPeriod(0, 'min {1-60}'), -1, 'should return -1 for minutes greater than 59 (right)');
