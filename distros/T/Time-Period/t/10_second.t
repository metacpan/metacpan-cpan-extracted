use strict;
use warnings;

use Test::More tests => 15;
use Time::Period;

use POSIX;
my $base_date = POSIX::mktime(0, 0, 0, 1, 0, 111); # 01/01/2011 00:00:00 (Saturday)

is(inPeriod($base_date, 'sec {0}'), 1, 'should match a single second');
is(inPeriod($base_date, 'second {0}'), 1, 'should match a single second, by the long form');
is(inPeriod($base_date - 1, 'sec {0}'), 0, 'should be able to not match a single second');

is(inPeriod($base_date + 1, 'sec {0-3}'), 1, 'should be able to match a range of seconds');
is(inPeriod($base_date - 1, 'sec {0-3}'), 0, 'should be able to not match a range of seconds');

is(inPeriod($base_date, 'sec {59-5}'), 1, 'should be able to match a range of days when the first second is greater than the second');
is(inPeriod($base_date - 1, 'sec {59-5}'), 1, 'should be able to match a range of days when the first second is greater than the second');
is(inPeriod($base_date - 20, 'sec {59-5}'), 0, 'should be able to not match a range of days when the first second is greater than the second');

is(inPeriod($base_date + 5, 'sec {1-2}'), 0, 'should be able to not match a range of days when the first second is less than the second');

is(inPeriod(0, 'sec {one}'), -1, 'should return -1 for non-numeric seconds (single)');
is(inPeriod(0, 'sec {one - 3}'), -1, 'should return -1 for non-numeric seconds (left)');
is(inPeriod(0, 'sec {3-one}'), -1, 'should return -1 for non-numeric seconds (right)');

is(inPeriod(0, 'sec {60}'), -1, 'should return -1 for seconds greater than 59 (single)');
is(inPeriod(0, 'sec {60-1}'), -1, 'should return -1 for seconds greater than 59 (left)');
is(inPeriod(0, 'sec {1-60}'), -1, 'should return -1 for seconds greater than 59 (right)');
