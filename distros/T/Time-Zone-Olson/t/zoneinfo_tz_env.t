#!perl -T
use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More;
use Time::Local();
use Time::Zone::Olson();
use POSIX();
use Config;
use Time::Local();
use File::Find();
use Digest::SHA();

$ENV{PATH} = '/bin:/usr/bin:/usr/sbin:/sbin';
delete @ENV{'IFS', 'CDPATH', 'ENV', 'BASH_ENV'};

my $test_gnu_date = `TZ="Australia/Melbourne" date -d "2015/02/28 11:00:00" +"%Y/%m/%d %H:%M:%S" 2>&1`;
if (defined $test_gnu_date) {
	chomp $test_gnu_date;
	ok(1, "Checking date is '$test_gnu_date', should be '2015/02/28 11:00:00'");
} else {
	diag(q['date -d "2015/02/28 11:00:00" +"%Y/%m/%d %H:%M:%S" 2>&1'] . " does not function correctly on '$^O'");
	ok(1, q['date -d "2015/02/28 11:00:00" +"%Y/%m/%d %H:%M:%S" 2>&1'] . " does not function correctly on '$^O'");
}
foreach my $tz (
			'EST5EDT,M3.2.0,M11.1.0',
			'<-04>4<-03>,M11.1.0/0,M2.3.0/0',
			'AEST-10AEDT,M10.1.0,M4.1.0/3'
		) {
	next unless (($test_gnu_date) && ($test_gnu_date eq '2015/02/28 11:00:00'));
	$ENV{TZ} = $tz;
	my $time = time;
	$time -= ($time % 3600);
	my %month_indexes;
	while ($tz =~ /M(\d+)[.]/smxg) {
		$month_indexes{$1} = 1;
	}
	DAY: foreach my $day ( 0 .. 365 ) {
		foreach my $hour ( 0 .. 24 ) {
			$time += 3600;	
			check_time($tz, $time, %month_indexes);
			check_time($tz, $time - 1, %month_indexes);
			check_time($tz, $time + 1, %month_indexes);
		}
	}
	my $zone = Time::Zone::Olson->new( timezone => $tz );
	ok($zone->equiv( $tz ), "'$tz' is equivalent to '$tz'");
	ok(!$zone->equiv( 'GMT0BST,M3.5.0/1,M10.5.0' ), "'GMT0BST,M3.5.0/1,M10.5.0' is NOT equivalent to '$tz'");
}

Test::More::done_testing();

sub check_time {
	my ($tz, $time, %month_indexes) = @_;
	my @time_local = Time::Zone::Olson->new()->local_time($time);
	return unless ($month_indexes{$time_local[4] + 1});
	return if (($time_local[2] > 5) && ($time_local[2] < 22));
	my $time_zone_olson = POSIX::strftime('%Y/%m/%d %H:%M:%S', @time_local);
	my $date = `date -d "\@$time" +"%Y/%m/%d %H:%M:%S"`;
	chomp $date;
	ok($time_zone_olson eq $date, "$time_zone_olson eq $date for the local_time time $time in $tz");
	my $revert_time = Time::Zone::Olson->new()->time_local(@time_local);
	ok($revert_time <= $time, "$revert_time (localtime " . (scalar localtime($revert_time)) . ") is returned for $time (localtime " . (scalar localtime($time)) . ") in time_local in $tz (offset of " . ($revert_time - $time) . " seconds)");
	ok($tz eq Time::Zone::Olson->new()->timezone(), "$tz is still the timezone");
}
