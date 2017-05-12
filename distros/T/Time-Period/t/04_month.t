use strict;
use warnings;

use Test::More tests => 27;
use Time::Period;

use POSIX;
my $base_date = POSIX::mktime(0, 0, 0, 1, 0, 111); # 01/01/2011 00:00:00 (Saturday)
my $month = 29 * 24 * 60 * 60;

is(inPeriod($base_date, 'mo {jan}'), 1, 'should match a single month');
is(inPeriod($base_date - $month, 'mo {jan}'), 0, 'should be able to not match a single month');

is(inPeriod($base_date, 'mo {dec-feb}'), 1, 'should be able to match a range of months');
is(inPeriod($base_date, 'mo {dec-feb}'), 1, 'should be able to not match a range of months');
is(inPeriod($base_date, 'mo {mar-oct}'), 0, 'should be able to not match a range when the first month comes before the second');

is(inPeriod($base_date - $month * 2, 'mo {oct-dec}'), 1, 'should be able to match a range of months');

is(inPeriod($base_date - $month * 2, 'mo {dec-oct}'), 0, 'should be able to not match a range when the first month comes after the second');
is(inPeriod($base_date - $month * 2, 'mo {dec-nov}'), 1, 'should "wrap around" to match ranges');

is(inPeriod($base_date, 'mo {feb-mar}'), 0, 'should be able to not match a range when the first month comes before the second');

is(inPeriod($base_date, 'mo {January}'), 1, 'should allow long month names (single)');
is(inPeriod($base_date, 'mo {foobar}'), -1, 'should return -1 for invalid month names (single)');
is(inPeriod($base_date, 'mo {1}'), 1, 'should allow numeric months (single)');
is(inPeriod($base_date, 'mo {17}'), -1, 'should return -1 for numeric months greater than 12 (single)');
is(inPeriod($base_date, 'mo {0}'), -1, 'should return -1 for numeric months less than 1 (single)');
is(inPeriod($base_date, 'mo {_}'), -1, 'should return -1 for non-alphanumeric months (single)');

is(inPeriod($base_date, 'mo {january - march}'), 1, 'should allow long month names (left)');
is(inPeriod($base_date, 'mo {foobar - march}'), -1, 'should return -1 for invalid month names (left)');
is(inPeriod($base_date, 'mo {1 - mar}'), 1, 'should allow numeric months (left)');
is(inPeriod($base_date, 'mo {17 - mar}'), -1, 'should return -1 for numeric months greater than 12 (left)');
is(inPeriod($base_date, 'mo {0 - mar}'), -1, 'should return -1 for numeric months less than 1 (left)');
is(inPeriod($base_date, 'mo {_ - mar}'), -1, 'should return -1 for non-alphanumeric months (left)');

is(inPeriod($base_date, 'mo {dec - january}'), 1, 'should allow long month names (right)');
is(inPeriod($base_date, 'mo {dec - foobar}'), -1, 'should return -1 for invalid month names (right)');
is(inPeriod($base_date, 'mo {dec - 1}'), 1, 'should allow numeric months (right)');
is(inPeriod($base_date, 'mo {6 - 17}'), -1, 'should return -1 for numeric months greater than 12 (right)');
is(inPeriod($base_date, 'mo {1 - 0}'), -1, 'should return -1 for numeric months less than 1 (right)');
is(inPeriod($base_date, 'mo {6 - _}'), -1, 'should return -1 for non-alphanumeric months (right)');

