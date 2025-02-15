use lib '../lib';
use lib '../blib';
use strict;
use warnings;
use Test::More tests => 24;

BEGIN {
	use_ok 'Time::Precise';
}

my $time = time;
my $ok = length($time) > length(int $time);
is $ok, 1, 'time has nanoseconds';

$time = '178983192.0067514';
my $gmtime = 'Wed Sep  3 13:33:12.0067514 1975';
is $gmtime, scalar(gmtime($time)), 'gmtime works with nanoseconds';

my $current_time = time;
sleep .1;
$current_time = time - $current_time;
$current_time = sprintf '%0.1f', $current_time;
# I've seen some machines run this really slowly... so it just should be less than 1
$ok = ($current_time > 0 and $current_time < 1) ? 1 : 0;
is $ok, 1, 'sleep works with nanoseconds';

my @gmtime = gmtime $time;
is timegm(@gmtime), $time, 'timelocal works with nanoseconds';

is is_valid_date(2000, 2, 29), 1, 'is_valid_year leap year';
is is_valid_date(2001, 2, 29), 0, 'is_valid_year non leap year';
is is_valid_date(2002, 1, 31), 1, 'is_valid_year long month A';
is is_valid_date(2002, 1, 32), 0, 'is_valid_year long month B';
is is_valid_date(2003, 4, 30), 1, 'is_valid_year short month A';
is is_valid_date(2003, 4, 31), 0, 'is_valid_year short month B';

my $h = gmtime_hashref($time);
is 'HASH', ref($h), 'gmtime_hashref returns hashref';
is $h->{year}, 1975, 'gmtime_hashref year';
is $h->{month}, '09', 'gmtime_hashref month';
is $h->{day}, '03', 'gmtime_hashref day';
is $h->{hour}, '13', 'gmtime_hashref hour';
is $h->{minute}, '33', 'gmtime_hashref minute';
is $h->{second}, '12.0067514', 'gmtime_hashref second';

my $time_from = get_gmtime_from (
	year 	=> 1975,
	month	=> 9,
	day		=> 3,
	hour	=> 13,
	minute	=> 33,
	second	=> 12.0067514,
);
is $time_from, $time, 'get_gmtime_from';

my $future_time = scalar gmtime '1444222866.7336199';
is $future_time, 'Wed Oct  7 13:01:06.7336199 2015', 'gmtime can go past year 2038';

my $past_time = scalar gmtime '0.7336199';
is $past_time, 'Thu Jan  1 00:00:00.7336199 1970', 'gmtime past time as expected';

SKIP: {
	skip 'Not a Perl >= 5.012', 1 if $] < 5.012;
	my $ac_time = scalar gmtime '-1444222866.7336199';
	is $ac_time =~ /^Thu Mar 27 10:58:5\d\.7336199 1924$/, 1, 'gmtime can go way back (negative seconds)';
}


my $lc_ts = localtime_ts($time);
my $gm_ts = gmtime_ts($time);
my ($sec, $min, $hour, $mday, $mon, $year, $wday, $yday, $isdst) = CORE::localtime($time);
my $lt_ts_str = sprintf '%04d-%02d-%02d %02d:%02d:%02d.0067514', $year + 1900, $mon + 1, $mday, $hour, $min, $sec;;
my $gm_ts_str = '1975-09-03 13:33:12.0067514';

is $lc_ts, $lt_ts_str, "localtime_ts is $lt_ts_str";
is $gm_ts, $gm_ts_str, "localtime_ts is $gm_ts_str";
