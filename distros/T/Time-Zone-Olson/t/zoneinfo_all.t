#!perl -T
use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More;
use Time::Local();
use Time::Zone::Olson();
use POSIX();
use Config;
use English qw( -no_match_vars );
use Time::Local();

$ENV{PATH} = '/bin:/usr/bin:/usr/sbin:/sbin';
delete @ENV{'IFS', 'CDPATH', 'ENV', 'BASH_ENV'};
if ($^O eq 'cygwin') {
	delete $ENV{PATH};
}

if ($ENV{TZ}) {
	diag("TZ environment variable is $ENV{TZ}");
}

my $timezone = Time::Zone::Olson->new();
ok($timezone, "Time::Zone::Olson->new() generates an object");
if ($timezone->win32_registry()) {
	diag("Olson tz directory is using the Win32 Registry for Olson tz calculations for $^O");
} else {
	diag("Olson tz directory is " . $timezone->directory() . " for $^O");
}

if (!$timezone->timezone()) {
	$timezone->timezone('UTC');
	diag("$^O does not have a default timezone, setting to " . $timezone->timezone());
}
diag("Local timezone has been determined to be " . $timezone->timezone() );
ok($timezone->timezone(), "Local timezone has been determined to be " . $timezone->timezone() );
if (defined $timezone->determining_path()) {
	diag("Local timezone was determined using " . $timezone->determining_path() );
}

my $perl_date = 0;
my $bsd_date = 0;
my $busybox_date = 0;
if ($^O eq 'MSWin32') {
	diag "$^O means we need to use the SystemTimeToTzSpecificLocalTime system call as the definitive source of truth for timezone calculations";
} elsif ($^O eq 'solaris') {
	diag "$^O does not have a useful date binary.";
	$perl_date = 1;
} else {
	my $test_gnu_date = `TZ="Australia/Melbourne" date -d "2015/02/28 11:00:00" +"%Y/%m/%d %H:%M:%S" 2>&1`;
	chomp $test_gnu_date;
	if (($test_gnu_date) && ($test_gnu_date eq '2015/02/28 11:00:00')) {
	} else {
		my $test_bsd_date = `TZ="Australia/Melbourne" date -r 1425081600 +"%Y/%m/%d %H:%M:%S" 2>&1`;
		chomp $test_bsd_date;
		if (($test_bsd_date) && ($test_bsd_date eq '2015/02/28 11:00:00')) {
			$bsd_date = 1;
		} else {
			my $test_busybox_date = `TZ="Australia/Melbourne" date -d "2015-02-28 11:00:00" 2>&1`;
			chomp $test_busybox_date;
			diag "Output of busybox date command:$test_busybox_date";
			if (($test_bsd_date) && ($test_bsd_date eq '2015/02/28 11:00:00')) {
				$busybox_date = 1;
			} else {
				$perl_date = 1;
			}
		}
	}
}

ok($timezone->timezone() =~ /^\w+(\/[\w\-\/+]+)?$/, "\$timezone->timezone() parses correctly");
if ($timezone->areas()) {
	ok((grep /^Australia$/, $timezone->areas()), "Found 'Australia' in \$timezone->areas()");
	ok((grep /^Melbourne$/, $timezone->locations('Australia')), "Found 'Melbourne' in \$timezone->areas('Australia')");
	if (!$timezone->win32_registry()) {
		my $comment = $timezone->comment('Australia/Melbourne');
		ok($comment =~ /Victoria/smx, "\$timezone->comment('Australia/Melbourne') contains /Victoria/");
		diag("Comment for 'Australia/Melbourne' is '$comment'");
	}
}
my $tz = $timezone->timezone();
my $directory = $timezone->directory();
if ($ENV{TZDIR}) {
	if ($directory =~ /^(.*)$/) {
		$directory = $1;
	}
}
my $current_year = (localtime)[5] + 1900;
my $start_year = $current_year - 3;
my $end_year = $current_year + 2;
if (($^O eq 'MSWin32') || ($^O eq 'cygwin')) {
} elsif ($^O eq 'solaris') {
	diag(`zdump -c $start_year,$end_year -v $tz | tail`);
} else {
	diag(`zdump -c $start_year,$end_year -v $directory/$tz | tail`);
}
my $todo;
if ($^O eq 'MSWin32') {
} elsif ($bsd_date) {
	diag("bsd test of early date:" . `TZ="Australia/Melbourne" date -r "-2172355201" +"%Y/%m/%d %H:%M:%S %Z" 2>&1`);
} elsif ($busybox_date) {
	diag("busybox test of early date:" . `TZ="Australia/Melbourne" date -d "1901-02-28 23:59:59 GMT" 2>&1`);
} elsif ($perl_date) {
	$todo = "perl does not always agree with date(1)";
} else {
	diag("gnu test of early date:" . `TZ="Australia/Melbourne" date -d "1901/02/28 23:59:59 GMT" +"%Y/%m/%d %H:%M:%S %Z" 2>&1`);
}
$TODO = $todo;

my $count = 0;
foreach my $area ($timezone->areas()) {
	foreach my $location ($timezone->locations($area)) {
		if ( $ENV{RELEASE_TESTING} ) {
		} else {
			next if ("$area/$location" ne $tz);
		}
		$timezone->timezone("$area/$location");
		my $transition_time_index = 0;
		foreach my $transition_time ($timezone->transition_times()) {
			if (($Config{archname} !~ /^(?:amd64|x86_64)/) && ($transition_time > (2 ** 31) - 1)) {
			} elsif (($Config{archname} !~ /^(?:amd64|x86_64)/) && ($transition_time < -2 ** 31)) {
			} else {
				eval { gmtime $transition_time } or do { next };
				my $correct_date = get_external_date($area, $location, $transition_time);
				my $test_date = POSIX::strftime("%Y/%m/%d %H:%M:%S", $timezone->local_time($transition_time)) . q[ ] . $timezone->local_abbr($transition_time);
				SKIP: {
					if ($correct_date) {
						ok($test_date eq $correct_date, "Matched $test_date to $correct_date for $area/$location for \$timezone->local_time($transition_time)");
					} else {
						skip("system 'date' command did not produce any output at all for $area/$location", 1);
					}
				}
				my $revert_time = $timezone->time_local($timezone->local_time($transition_time));
				ok($revert_time <= $transition_time, "\$timezone->time_local(\$timezone->local_time(\$transition_time)) <= \$transition_time where $revert_time = $transition_time with a difference of " . ($revert_time - $transition_time) . " for $area/$location"); 
				my $revert_date = get_external_date($area, $location, $revert_time);
				SKIP: {
					if ($correct_date) {
						ok(strip_external_date($revert_date) eq strip_external_date($correct_date), "Matched $revert_date to $correct_date for $area/$location for \$timezone->time_local");
					} else {
						skip("system 'date' command did not produce any output at all for $area/$location", 1);
					}
				}
				SKIP: {
					local %ENV = %ENV;
					$ENV{TZ} = "$area/$location";
					my @local_time = $timezone->local_time($transition_time);
					$local_time[5] += 1900;
					my $time_local;
					eval {
						$time_local = Time::Local::timelocal(@local_time);
					} or do {
						chomp $@;
						skip("Time::Local::timelocal("  . join(',', @local_time) . ") threw an exception:$@", 1);
					};
					if ($revert_time <= $time_local) {
						ok($revert_time <= $time_local, "\$timezone->time_local() <= Time::Local::time_local() where $revert_time = $time_local with a difference of " . ($revert_time - $time_local) . " for $area/$location"); 
					} else {
						my $test_time_local = get_external_date($area, $location, $time_local);
						SKIP: {
							if ($correct_date and $test_time_local) {
								if ($test_time_local eq $correct_date) {
									ok($revert_time <= $time_local, "\$timezone->time_local() <= Time::Local::time_local() where $revert_time = $time_local with a difference of " . ($revert_time - $time_local) . " for $area/$location"); 
								} else {
									diag("Time::Local::local_time(" . join(',', @local_time) . ") returned $time_local which translated back to $test_time_local for $area/$location");
								}
							} else {
								skip("system 'date' command did not produce any output at all for $area/$location", 1);
							}
						}
					}
				}
				$transition_time -= 1;
				$correct_date = get_external_date($area, $location, $transition_time);
				$test_date = POSIX::strftime("%Y/%m/%d %H:%M:%S", $timezone->local_time($transition_time)) . q[ ] . $timezone->local_abbr($transition_time);
				SKIP: {
					if ($correct_date) {
						ok($test_date eq $correct_date, "Matched $test_date to $correct_date for $area/$location for \$timezone->local_time - 1");
					} else {
						skip("system 'date' command did not produce any output at all for $area/$location", 1);
					}
				}
				$revert_time = $timezone->time_local($timezone->local_time($transition_time));
				ok($revert_time <= $transition_time, "\$timezone->time_local(\$timezone->local_time(\$transition_time)) <= \$transition_time where $revert_time = $transition_time with a difference of " . ($revert_time - $transition_time) . " for $area/$location"); 
				$revert_date = get_external_date($area, $location, $revert_time);
				SKIP: {
					if ($correct_date) {
						ok(strip_external_date($revert_date) eq strip_external_date($correct_date), "Matched $revert_date to $correct_date for $area/$location for \$timezone->time_local - 1");
					} else {
						skip("system 'date' command did not produce any output at all for $area/$location", 1);
					}
				}
				SKIP: {
					local %ENV = %ENV;
					$ENV{TZ} = "$area/$location";
					my @local_time = $timezone->local_time($transition_time);
					$local_time[5] += 1900;
					my $time_local;
					eval {
						$time_local = Time::Local::timelocal(@local_time);
					} or do {
						chomp $@;
						skip("Time::Local::timelocal("  . join(',', @local_time) . ") threw an exception:$@", 1);
					};
					if ($revert_time <= $time_local) {
						ok($revert_time <= $time_local, "\$timezone->time_local() <= Time::Local::time_local() where $revert_time = $time_local with a difference of " . ($revert_time - $time_local) . " for $area/$location"); 
					} else {
						my $test_time_local = get_external_date($area, $location, $time_local);
						SKIP: {
							if ($correct_date and $test_time_local) {
								if ($test_time_local eq $correct_date) {
									ok($revert_time <= $time_local, "\$timezone->time_local() <= Time::Local::time_local() where $revert_time = $time_local with a difference of " . ($revert_time - $time_local) . " for $area/$location"); 
								} else {
									diag("Time::Local::local_time(" . join(',', @local_time) . ") returned $time_local which translated back to $test_time_local for $area/$location");
								}
							} else {
								skip("system 'date' command did not produce any output at all for $area/$location", 1);
							}
						}
					}
				}

				$transition_time += 2;
				$correct_date = get_external_date($area, $location, $transition_time);
				$test_date = POSIX::strftime("%Y/%m/%d %H:%M:%S", $timezone->local_time($transition_time)) . q[ ] . $timezone->local_abbr($transition_time);
				SKIP: {
					if ($correct_date) {
						ok($test_date eq $correct_date, "Matched $test_date to $correct_date for $area/$location for \$timezone->local_time + 1");
					} else {
						skip("system 'date' command did not produce any output at all for $area/$location", 1);
					}
				}
				$revert_time = $timezone->time_local($timezone->local_time($transition_time));
				ok($revert_time <= $transition_time, "\$timezone->time_local(\$timezone->local_time(\$transition_time)) <= \$transition_time where $revert_time = $transition_time with a difference of " . ($revert_time - $transition_time) . " for $area/$location"); 
				$revert_date = get_external_date($area, $location, $revert_time);
				SKIP: {
					if ($correct_date) {
						ok(strip_external_date($revert_date) eq strip_external_date($correct_date), "Matched $revert_date to $correct_date for $area/$location for \$timezone->time_local + 1");
					} else {
						skip("system 'date' command did not produce any output at all for $area/$location", 1);
					}
				}
				SKIP: {
					local %ENV = %ENV;
					$ENV{TZ} = "$area/$location";
					my @local_time = $timezone->local_time($transition_time);
					$local_time[5] += 1900;
					my $time_local;
					eval {
						$time_local = Time::Local::timelocal(@local_time);
					} or do {
						chomp $@;
						skip("Time::Local::timelocal("  . join(',', @local_time) . ") threw an exception:$@", 1);
					};
					if ($revert_time <= $time_local) {
						ok($revert_time <= $time_local, "\$timezone->time_local() <= Time::Local::time_local() where $revert_time = $time_local with a difference of " . ($revert_time - $time_local) . " for $area/$location"); 
					} else {
						my $test_time_local = get_external_date($area, $location, $time_local);
						SKIP: {
							if ($correct_date and $test_time_local) {
								if ($test_time_local eq $correct_date) {
									ok($revert_time <= $time_local, "\$timezone->time_local() <= Time::Local::time_local() where $revert_time = $time_local with a difference of " . ($revert_time - $time_local) . " for $area/$location"); 
								} else {
									diag("Time::Local::local_time(" . join(',', @local_time) . ") returned $time_local which translated back to $test_time_local for $area/$location");
								}
							} else {
								skip("system 'date' command did not produce any output at all for $area/$location", 1);
							}
						}
					}
				}
				$transition_time_index += 1;
				$count += 1;
				$count = $count % 2;
				if (defined $timezone->tz_definition()) {
					ok($timezone->tz_definition(), "TZ definition for $area/$location is " . $timezone->tz_definition());
				}
				if ($count == 0) {
					Time::Zone::Olson->reset_cache();
					$timezone = Time::Zone::Olson->new();
					$timezone->timezone("$area/$location");
				} else {
					$timezone->reset_cache();
				}
			}
		}
	}
}

sub strip_external_date {
	my ($date) = @_;
	if ($date =~ /^(\d{4}\/\d{2}\/\d{2}[ ]\d{2}:\d{2}:\d{2})[ ]/smx) {
		return $1;
	} else {
		warn "Failed to parse date";
		return $date;
	}
}

sub get_external_date {
	my ($area, $location, $unix_time) = @_;
	my $untainted_unix_time;
	if ($unix_time =~ /^(\-?\d+)$/) {
		($untainted_unix_time) = ($1);
	} else {
		die "Failed to parse transition time $unix_time";
	}
	my $formatted_date;
	if ($^O eq 'MSWin32') {
		my $perl_path = 'perl';
		if ($^X =~ /^([\w\\.:]+)/) {
			($perl_path) = ($1);
		} else {
			die "Failed to parse $^X";
		}

		my %mapping = Time::Zone::Olson->win32_mapping();
		my $win32_time_zone = $mapping{"$area/$location"};
		require Win32::API;
		
		my $timezone_specific_registry_path = "SOFTWARE\\Microsoft\\Windows NT\\CurrentVersion\\Time Zones\\" . $mapping{"$area/$location"};
		Win32API::Registry::RegOpenKeyEx(Win32API::Registry::HKEY_LOCAL_MACHINE(), $timezone_specific_registry_path, 0, Win32API::Registry::KEY_QUERY_VALUE(), my $timezone_specific_subkey) or Carp::croak( "Failed to open LOCAL_MACHINE\\$timezone_specific_registry_path:$EXTENDED_OS_ERROR");
		Win32API::Registry::RegQueryValueEx( $timezone_specific_subkey, 'Dlt', [], [], my $daylight_name, []) or Carp::croak("Failed to read LOCAL_MACHINE\\$timezone_specific_registry_path\\TZI:$EXTENDED_OS_ERROR");
		Win32API::Registry::RegQueryValueEx( $timezone_specific_subkey, 'Std', [], [], my $standard_name, []) or Carp::croak("Failed to read LOCAL_MACHINE\\$timezone_specific_registry_path\\TZI:$EXTENDED_OS_ERROR");
		Win32API::Registry::RegQueryValueEx( $timezone_specific_subkey, 'TZI', [], [], my $binary, []) or Carp::croak("Failed to read LOCAL_MACHINE\\$timezone_specific_registry_path\\TZI:$EXTENDED_OS_ERROR");
		my ($bias, $standard_bias, $daylight_bias, $standard_year, $standard_month, $standard_day_of_week, $standard_week, $standard_hour, $standard_minute, $standard_second, $standard_millisecond, $daylight_year, $daylight_month, $daylight_day_of_week, $daylight_week, $daylight_hour, $daylight_minute, $daylight_second, $daylight_millisecond) = unpack 'lllSSSSSSSSSSSSSSSS', $binary;
		Win32::API::Struct->typedef(SYSTEMTIME => qw(
			WORD wYear;
			WORD wMonth;
			WORD wDayOfWeek;
			WORD wDay;
			WORD wHour;
			WORD wMinute;
			WORD wSecond;
			WORD wMilliseconds;
		));
		Win32::API::Struct->typedef(TIME_ZONE_INFORMATION => qw(
			LONG       Bias;
			WCHAR      StandardName[32];
			SYSTEMTIME StandardDate;
			LONG       StandardBias;
			WCHAR      DaylightName[32];
			SYSTEMTIME DaylightDate;
			LONG       DaylightBias;
		));

		my $tzi = Win32::API::Struct->new('TIME_ZONE_INFORMATION');
		$tzi->{Bias} = $bias;
		$tzi->{StandardName} = $standard_name;
		$tzi->{StandardDate}{wYear} = $standard_year;
		$tzi->{StandardDate}{wMonth} = $standard_month;
		$tzi->{StandardDate}{wDayOfWeek} = $standard_day_of_week;
		$tzi->{StandardDate}{wDay} = $standard_week;
		$tzi->{StandardDate}{wHour} = $standard_hour;
		$tzi->{StandardDate}{wMinute} = $standard_minute;
		$tzi->{StandardDate}{wSecond} = $standard_second;
		$tzi->{StandardDate}{wMilliseconds} = $standard_millisecond;
		$tzi->{StandardBias} = $standard_bias;
		$tzi->{DaylightName} = $daylight_name;
		$tzi->{DaylightDate}{wYear} = $daylight_year;
		$tzi->{DaylightDate}{wMonth} = $daylight_month;
		$tzi->{DaylightDate}{wDayOfWeek} = $daylight_day_of_week;
		$tzi->{DaylightDate}{wDay} = $daylight_week;
		$tzi->{DaylightDate}{wHour} = $daylight_hour;
		$tzi->{DaylightDate}{wMinute} = $daylight_minute;
		$tzi->{DaylightDate}{wSecond} = $daylight_second;
		$tzi->{DaylightDate}{wMilliseconds} = $daylight_millisecond;
		$tzi->{DaylightBias} = $daylight_bias;

		my $gmt_time = Win32::API::Struct->new('SYSTEMTIME');
		$gmt_time->{wYear} = ((gmtime($unix_time))[5])  + 1900;
		$gmt_time->{wMonth} = ((gmtime($unix_time))[4]) + 1;
		$gmt_time->{wDayOfWeek} = ((gmtime($unix_time))[6]);
		$gmt_time->{wDay} = ((gmtime($unix_time))[3]);
		$gmt_time->{wHour} = ((gmtime($unix_time))[2]);
		$gmt_time->{wMinute} = ((gmtime($unix_time))[1]);
		$gmt_time->{wSecond} = ((gmtime($unix_time))[0]);
		$gmt_time->{wMilliseconds} = 0;

		my $local_time = Win32::API::Struct->new('SYSTEMTIME');
		$local_time->{wYear} = 0;
		$local_time->{wMonth} = 0;
		$local_time->{wDayOfWeek} = 0;
		$local_time->{wDay} = 0;
		$local_time->{wHour} = 0;
		$local_time->{wMinute} = 0;
		$local_time->{wSecond} = 0;
		$local_time->{wMilliseconds} = 0;
		
		my $system_time_to_tz_specific_local_time = Win32::API::More->new("kernel32", "BOOL WINAPI SystemTimeToTzSpecificLocalTime(LPTIME_ZONE_INFORMATION lpTimeZone, LPSYSTEMTIME lpUniversalTime, LPSYSTEMTIME lpLocalTime);");
		my $result = $system_time_to_tz_specific_local_time->Call($tzi,$gmt_time, $local_time);
		if ($result == 0) { warn "Failed SystemTimeToTzSpecificLocalTime:$^E" }
		foreach my $key (sort {$a cmp $b } keys %{$local_time}) {
			$local_time->{$key} =~ s/^(\d)$/0$1/smx;
		}
		$formatted_date = $local_time->{wYear} . q[/] . $local_time->{wMonth} . q[/] . $local_time->{wDay} . q[ ] . $local_time->{wHour} . q[:] . $local_time->{wMinute} . q[:] . $local_time->{wSecond};
	} elsif ($perl_date) {
		$formatted_date = `TZ="$area/$location" perl -MPOSIX -e 'print POSIX::strftime("%Y/%m/%d %H:%M:%S %Z", localtime($untainted_unix_time))'`;
	} elsif ($bsd_date) {
		$formatted_date = `TZ="$area/$location" date -r $untainted_unix_time +"%Y/%m/%d %H:%M:%S %Z"`;
	} elsif ($busybox_date) {
		my $gm_strftime = POSIX::strftime("%Y-%m-%d %H:%M:%S GMT", gmtime $untainted_unix_time);
		$formatted_date = `TZ="$area/$location" date -d "$gm_strftime"`;
	} else {
		my $gm_strftime = POSIX::strftime("%Y/%m/%d %H:%M:%S GMT", gmtime $untainted_unix_time);
		$formatted_date = `TZ="$area/$location" date -d "$gm_strftime" +"%Y/%m/%d %H:%M:%S %Z"`;
	}
	if ($? != 0) {
		diag("external date command exited with a $? for $area/$location at " . POSIX::strftime("%Y/%m/%d %H:%M:%S GMT", gmtime $untainted_unix_time));
	}
	chomp $formatted_date;
	return $formatted_date;
}

Test::More::done_testing();
