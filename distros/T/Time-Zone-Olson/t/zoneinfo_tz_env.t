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
my %dates;
my $max_number_of_years = 0;
if ($ENV{RELEASE_TESTING}) {
	$max_number_of_years = 20;
}
foreach my $tz (
				($] >= 5.010 ? '<+0330>-3:30<+0430>,79/24,263/24' : ()),
				'<+0330>-3:30<+0430>,J79/24,J263/24',
				'WET0WEST,M3.5.0,M10.5.0/3',
				'EST5EDT,M3.2.0,M11.1.0',
				'<-04>4<-03>,M11.1.0/0,M2.3.0/0',
				'AEST-10AEDT,M10.1.0,M4.1.0/3',
				'NZST-12NZDT,M9.5.0,M4.1.0/3',
		)
{
	foreach my $number_of_years ( ( 0 .. $max_number_of_years )) {
		next unless (($test_gnu_date) && ($test_gnu_date eq '2015/02/28 11:00:00'));
		my $time = Time::Zone::Olson->new( timezone => $tz )->time_local(0,0,0,1,0,118 + $number_of_years);
		%dates = ();
		$time -= ($time % 3600);
		DAY: foreach my $day ( 0 .. 365 ) {
			foreach my $hour ( 0 .. 24 ) {
				$time += 3600;	
				check_time($tz, $time - 1);
				check_time($tz, $time);
				check_time($tz, $time + 1);
			}
		}
		my $doubles = 0;
		foreach my $date (sort { $a cmp $b } keys %dates) {
			if ($dates{$date} > 1) {
				$doubles += 1;
			}
		}
		ok($doubles == 3, "Found $doubles doubles");
		my $zone = Time::Zone::Olson->new( timezone => $tz );
		ok($zone->equiv( $tz ), "'$tz' is equivalent to '$tz'");
		ok(!$zone->equiv( 'GMT0BST,M3.5.0/1,M10.5.0' ), "'GMT0BST,M3.5.0/1,M10.5.0' is NOT equivalent to '$tz'");
	}
}
foreach my $tz (
			'<GMT+10>+10', 
			'<+07>-7',
			($] >= 5.010 ? ('UTC', 'Etc/GMT-0') : ()),
		) {
        next if ($^O eq 'MSWin32');
	my $zone = Time::Zone::Olson->new(timezone => $tz);
	ok($zone->timezone() eq $tz, "Allowed to specify an odd timezone such as '$tz'");
}

Test::More::done_testing();

sub _LOCALTIME_MINUTE_INDEX { return 1 }
sub _LOCALTIME_HOUR_INDEX { return 2 }
sub _LOCALTIME_DAY_INDEX { return 3 }
sub _LOCALTIME_MONTH_INDEX { return 4 }
sub _LOCALTIME_DAY_OF_WEEK_INDEX { return 6 }
sub _LOCALTIME_DAY_OF_YEAR_INDEX { return 7 }

sub check_time {
	my ($tz, $time) = @_;
	my @time_local = Time::Zone::Olson->new(timezone => $tz)->local_time($time);
	my $match;
	my $ok;
	while ($tz =~ /M(\d+)[.](\d+)[.](\d+)(?:\/(\d+))?/smxg) {
		my ($month, $week, $day, $hour) = ($1, $2, $3, $4);
		$hour = defined $hour ? $hour : 2;
		$ok = 1;
		if ($hour == 0) {
			return if (($time_local[_LOCALTIME_HOUR_INDEX()] > $hour + 1) && ($time_local[_LOCALTIME_HOUR_INDEX()] < 23));
		} else {
			return if (($time_local[_LOCALTIME_HOUR_INDEX()] > $hour + 1) || ($time_local[_LOCALTIME_HOUR_INDEX()] < $hour - 1));
		}
		if ($time_local[_LOCALTIME_HOUR_INDEX()] == $hour) {
			return unless (($time_local[_LOCALTIME_MINUTE_INDEX()] == 59) || ($time_local[_LOCALTIME_MINUTE_INDEX()] == 0) || ($time_local[_LOCALTIME_MINUTE_INDEX()] == 1));
		}
		if ($month == ($time_local[_LOCALTIME_MONTH_INDEX()] + 1)) {
			if ($week == 1) {
				if (($time_local[_LOCALTIME_DAY_INDEX()]) < 8) {
					if ($day == 0) {
						if ((($time_local[_LOCALTIME_DAY_OF_WEEK_INDEX()]) == 0) || ($time_local[_LOCALTIME_DAY_OF_WEEK_INDEX()] == 7)) {
							$match = 1;
						} elsif (($hour == 0) && ($time_local[_LOCALTIME_HOUR_INDEX()] == 23) && ($time_local[_LOCALTIME_DAY_OF_WEEK_INDEX()]) == 6) {
							$match = 1;
						}
					}
				}
			} elsif ($week == 2) {
				if ((($time_local[_LOCALTIME_DAY_INDEX()]) >= 7) && ($time_local[_LOCALTIME_DAY_INDEX()] < 15)) {
					if ($day == 0) {
						if ((($time_local[_LOCALTIME_DAY_OF_WEEK_INDEX()]) == 0) || ($time_local[_LOCALTIME_DAY_OF_WEEK_INDEX()] == 7)) {
							$match = 1;
						} elsif (($hour == 0) && ($time_local[_LOCALTIME_HOUR_INDEX()] == 23) && ($time_local[_LOCALTIME_DAY_OF_WEEK_INDEX()]) == 6) {
							$match = 1;
						}
					}
				}
			} elsif ($week == 3) {
				if ((($time_local[_LOCALTIME_DAY_INDEX()]) >= 14) && ($time_local[_LOCALTIME_DAY_INDEX()] < 22)) {
					if ($day == 0) {
						if ((($time_local[_LOCALTIME_DAY_OF_WEEK_INDEX()]) == 0) || ($time_local[_LOCALTIME_DAY_OF_WEEK_INDEX()] == 7)) {
							$match = 1;
						} elsif (($hour == 0) && ($time_local[_LOCALTIME_HOUR_INDEX()] == 23) && ($time_local[_LOCALTIME_DAY_OF_WEEK_INDEX()]) == 6) {
							$match = 1;
						}
					}
				}
			} elsif ($week == 5) {
				if (($time_local[_LOCALTIME_DAY_INDEX()]) > 20) {
					if ($day == 0) {
						if ((($time_local[_LOCALTIME_DAY_OF_WEEK_INDEX()]) == 0) || ($time_local[_LOCALTIME_DAY_OF_WEEK_INDEX()] == 7)) {
							$match = 1;
						} elsif (($hour == 0) && ($time_local[_LOCALTIME_HOUR_INDEX()] == 23) && ($time_local[_LOCALTIME_DAY_OF_WEEK_INDEX()]) == 6) {
							$match = 1;
						}
					}
				}
			} else {
				die "Unknown TZ format for week";
			}
		}
	}
	while ($tz =~ /[J,](\d+)(?:\/(\d+))?/smxg) {
		my ($day, $hour) = ($1, $2);
		$hour = defined $hour ? $hour : 2;
		$ok = 1;
		if ($hour == 0) {
			return if (($time_local[_LOCALTIME_HOUR_INDEX()] > $hour + 1) && ($time_local[_LOCALTIME_HOUR_INDEX()] < 23));
		} else {
			return if (($time_local[_LOCALTIME_HOUR_INDEX()] > $hour + 1) || ($time_local[_LOCALTIME_HOUR_INDEX()] < $hour - 1));
		}
		if (($time_local[_LOCALTIME_DAY_OF_YEAR_INDEX()] >= $day - 2) && ($time_local[_LOCALTIME_DAY_OF_YEAR_INDEX()] <= $day + 2)) {
			$match = 1;
		}
	}
	if (!$ok) {
		die "Weird TZ format";
	}
	return unless ($match);
	my $time_zone_olson = POSIX::strftime('%Y/%m/%d %H:%M:%S', @time_local);
	$dates{$time_zone_olson} += 1;
	my $date = `TZ='$tz' date -d "\@$time" +"%Y/%m/%d %H:%M:%S"`;
	chomp $date;
	ok($time_zone_olson eq $date, "$time_zone_olson eq $date for the local_time time $time in $tz");
	{
		local $ENV{TZ} = $tz;
		my $revert_time = Time::Zone::Olson->new()->time_local(@time_local);
		ok($revert_time <= $time, "$revert_time (localtime " . (scalar localtime($revert_time)) . ") is returned for $time (localtime " . (scalar localtime($time)) . ") in time_local in $tz (offset of " . ($revert_time - $time) . " seconds)");
		ok($tz eq Time::Zone::Olson->new()->timezone(), "$tz is the timezone from the environment variable TZ");
	}
}
