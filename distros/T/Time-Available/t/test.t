#!/usr/bin/perl

use Test::More tests => 41;
use blib;

use Time::Available qw(:days :fmt_interval);
use Time::Local;

my $debug = shift @ARGV;

my $tz_offset = time()-timegm(localtime);

my $i = Time::Available->new( start=>'07', end=>'17:15', dayMask=>DAY_WEEKDAY);
ok( defined($i) , 'new() work');

ok( defined($i->{start_arr}), 'start_arr');
cmp_ok( $i->{start_arr}[0], '==', 0, 'start_arr[0]');
cmp_ok( $i->{start_arr}[1], '==', 0, 'start_arr[1]');
cmp_ok( $i->{start_arr}[2], '==', 7, 'start_arr[2]');

ok( defined($i->{end_arr}), 'end_arr');
cmp_ok( $i->{end_arr}[0], '==', 0, 'end_arr[0]');
cmp_ok(	$i->{end_arr}[1], '==', 15, 'end_arr[1]');
cmp_ok( $i->{end_arr}[2], '==', 17, 'end_arr[2]');

my $t = 1 * 24;	# 1d
$t += 11;	# 11 hr
$t *= 60;
$t += 11;	# 11 min
$t *= 60;
$t += 11;	# 11 sec

cmp_ok( fmt_interval($t), 'eq', '1d 11:11:11', 'fmt_interval output ok');

# 20000 = Thu Jan  1 06:33:20 1970
# 30000 = Thu Jan  1 09:20:00 1970
# 50000 = Thu Jan  1 14:53:20 1970
# 60000 = Thu Jan  1 17:40:00 1970

# test this timespan (07:00-17:15) with above values

cmp_ok( $i->uptime(20000), '==', 36900, 'update(20000)');
cmp_ok( $i->uptime(30000), '==', 28500, 'uptime(30000)');
cmp_ok( $i->uptime(50000), '==', 8500, 'uptime(50000)');
cmp_ok( $i->uptime(60000), '==', 0, 'uptime(60000)');

# create and test timespan which spans over midnight

$i = Time::Available->new( start=>'17:15', end=>'07:00', dayMask=>DAY_THURSDAY);
ok( defined($i->{start_arr}), 'start_arr' );
cmp_ok( $i->{start_arr}[0], '==', 0, 'start_arr[0]');
cmp_ok( $i->{start_arr}[1], '==', 15, 'start_arr[1]');
cmp_ok(	$i->{start_arr}[2], '==', 17, 'start_arr[2]');

ok( defined($i->{end_arr}), 'end_arr');
cmp_ok( $i->{end_arr}[0], '==', 0, 'end_arr[0]');
cmp_ok( $i->{end_arr}[1], '==', 0, 'end_arr[1]');
cmp_ok( $i->{end_arr}[2], '==', 7, 'end_arr[2]');

cmp_ok($i->uptime(20000), '==', 29500, 'uptime(20000)');
cmp_ok($i->uptime(30000), '==', 27900, 'uptime(30000)');
cmp_ok($i->uptime(50000), '==', 27900, 'uptime(50000)');
cmp_ok($i->uptime(60000), '==', 26400, 'uptime(60000)');

# test day constants
my @days = (
	DAY_MONDAY,
	DAY_TUESDAY,
	DAY_WEDNESDAY,
	DAY_THURSDAY,
	DAY_FRIDAY,
	DAY_SATURDAY,
	DAY_SUNDAY,
);

my $week = 0;

foreach my $d (@days) {
	ok($d, "day $d");
	$week += $d;
}

cmp_ok($week, '==', DAY_EVERYDAY, "whole week");

cmp_ok(DAY_WEEKDAY + DAY_WEEKEND, '==', DAY_EVERYDAY, "weekday+weekend");

cmp_ok(DAY_EVERYDAY - DAY_SATURDAY - DAY_SUNDAY, '==', DAY_WEEKDAY, "weekday");
cmp_ok(DAY_SATURDAY + DAY_SUNDAY, '==', DAY_WEEKEND, "weekend");

$i = Time::Available->new( start=>'00:00', end=>'23:59', dayMask=>DAY_SUNDAY);
cmp_ok($i->_dayOk(0), '==', 1, '_dayOk(0)');

$i = Time::Available->new( start=>'00:00', end=>'23:59', dayMask=>DAY_MONDAY);
cmp_ok($i->_dayOk(1), '==', 1, '_dayOk(1)');


# check for bugfix
$i = Time::Available->new( start=>'07:00', end=>'17:00', dayMask=>DAY_WEEKDAY, DEBUG=>$debug);
cmp_ok($i->interval(1104358156, 1104381213), '==', 0, 'interval');
cmp_ok($i->interval(1137933377, 1137997561), '==', 1561, 'interval');

