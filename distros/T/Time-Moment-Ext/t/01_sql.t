use strict;
use Test::More 0.98;

use_ok 'Time::Moment::Ext';

my $test_str1 = '2015-01-20 12:20:00';
my $test_str2 = '2015-01-18';

my $tm1 = Time::Moment::Ext->from_datetime($test_str1);

ok($tm1, 'from_datetime. datetime string');

ok($tm1->year == 2015 && $tm1->month == 1 && $tm1->day == 20 && $tm1->hour == 12 && $tm1->minute == 20 && $tm1->second == 0, 'from_string check');

ok($tm1->to_datetime eq $test_str1, 'to_datetime');

my $tm2 = Time::Moment::Ext->from_datetime($test_str2);

ok($tm2, 'from_datetime. date only');

ok($tm2->year == 2015 && $tm2->month == 1 && $tm2->day == 18 && $tm2->hour == 0 && $tm2->minute == 0 && $tm2->second == 0, 'from_string check');

ok($tm2->to_date eq $test_str2, 'to_date');

ok($tm2->to_time eq '00:00:00', 'to_time');

done_testing;

