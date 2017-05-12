use strict;
use warnings;

use Test::More tests => 33;
use Time::Period;

use POSIX;
my $base_date = POSIX::mktime(0, 0, 0, 1, 0, 111); # 01/01/2011 00:00:00 (Saturday)
my $hour = 60 * 60;

is(inPeriod($base_date, 'hr {0}'), 1, 'should match a single hour');
is(inPeriod($base_date, 'hour {0}'), 1, 'should match a single hour, by the long form');
is(inPeriod($base_date - $hour, 'hr {0}'), 0, 'should be able to not match a single hour');

is(inPeriod($base_date + $hour, 'hr {0-3}'), 1, 'should be able to match a range of hours');
is(inPeriod($base_date - $hour, 'hr {0-3}'), 0, 'should be able to not match a range of hours');

is(inPeriod($base_date, 'hr {23-5}'), 1, 'should be able to match a range of days when the first hour is greater than the second');
is(inPeriod($base_date - $hour, 'hr {23-5}'), 1, 'should be able to match a range of days when the first hour is greater than the second');
is(inPeriod($base_date - $hour * 2, 'hr {23-5}'), 0, 'should be able to not match a range of days when the first hour is greater than the second');

is(inPeriod($base_date + $hour * 5, 'hr {1-2}'), 0, 'should be able to not match a range of days when the first hour is less than the second');

is(inPeriod(0, 'hr {one}'), -1, 'should return -1 for non-numeric hours (single)');
is(inPeriod(0, 'hr {one - 3}'), -1, 'should return -1 for non-numeric hours (left)');

is(inPeriod(0, 'hr {24}'), -1, 'should return -1 for hours greater than 23 (single)');
is(inPeriod(0, 'hr {24-1}'), -1, 'should return -1 for hours greater than 23 (left)');

is(inPeriod($base_date, 'hr {12am}'), 1, '12am should be treated as midnight (single)');
is(inPeriod($base_date, 'hr {12am-1}'), 1, '12am should be treated as midnight (left)');
is(inPeriod($base_date, 'hr {23-12am}'), 1, '12am should be treated as midnight (right)');

is(inPeriod($base_date + $hour, 'hr {1am}'), 1, '"am" times should not be altered (single)');
is(inPeriod($base_date + $hour, 'hr {1am-2}'), 1, '"am" times should not be altered (left)');
is(inPeriod($base_date + $hour, 'hr {0-1am}'), 1, '"am" times should not be altered (left)');

is(inPeriod($base_date + $hour * 12, 'hr {12noon}'), 1, '12noon should be treated as 12pm (single)');
is(inPeriod($base_date + $hour * 12, 'hr {12noon-13}'), 1, '12noon should be treated as 12pm (left)');
is(inPeriod($base_date + $hour * 12, 'hr {11-12noon}'), 1, '12noon should be treated as 12pm (right)');

is(inPeriod(0, 'hr {13noon}'), -1, 'only "12noon" is valid -- not 13noon (single)');
is(inPeriod(0, 'hr {13noon-13}'), -1, 'only "12noon" is valid -- not 13noon (left)');
is(inPeriod(0, 'hr {11-13noon}'), -1, 'only "12noon" is valid -- not 13noon (right)');

is(inPeriod($base_date + $hour * 13, 'hr {1pm}'), 1, '"pm" times should have 12 hours added to them (single)');
is(inPeriod($base_date + $hour * 13, 'hr {1pm-13}'), 1, '"pm" times should have 12 hours added to them (left)');
is(inPeriod($base_date + $hour * 13, 'hr {11-1pm}'), 1, '"pm" times should have 12 hours added to them (right)');

is(inPeriod($base_date + $hour * 12, 'hr {12pm}'), 1, '12pm should be treated as noon (single)');
is(inPeriod($base_date + $hour * 12, 'hr {12pm-13}'), 1, '12pm should be treated as noon (left)');
is(inPeriod($base_date + $hour * 12, 'hr {11-12pm}'), 1, '12pm should be treated as noon (right)');

is(inPeriod(0, 'hr {3 - one}'), -1, 'should return -1 for non-numeric hours (right)');
is(inPeriod(0, 'hr {1-24}'), -1, 'should return -1 for hours greater than 23 (right)');
