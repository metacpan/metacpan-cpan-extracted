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
use File::Find();
use Digest::SHA();

$ENV{PATH} = '/bin:/usr/bin:/usr/sbin:/sbin';
delete @ENV{'IFS', 'CDPATH', 'ENV', 'BASH_ENV'};

$ENV{TZ} ||= guess_tz();

diag("TZ environment variable is $ENV{TZ}");

my $timezone = Time::Zone::Olson->new();
ok($timezone, "Time::Zone::Olson->new() generates an object");
if ($timezone->win32_registry()) {
	diag("Olson tz directory is using the Win32 Registry for Olson tz calculations for $^O");
} else {
	diag("Olson tz directory is " . $timezone->directory() . " for $^O");
}

if ($timezone->location()) {
	$ENV{TZ} = $timezone->area() . '/' . $timezone->location();
} else {
	$ENV{TZ} = $timezone->area();
}
diag("TZ environment variable is untainted as $ENV{TZ}");

my $perl_date = 0;
my $bsd_date = 0;
my $test_gnu_date = `TZ="Australia/Melbourne" date -d "2015/02/28 11:00:00" +"%Y/%m/%d %H:%M:%S" 2>&1`;
if (defined $test_gnu_date) {
	chomp $test_gnu_date;
}
if (($test_gnu_date) && ($test_gnu_date eq '2015/02/28 11:00:00')) {
} else {
	my $test_bsd_date = `TZ="Australia/Melbourne" date -r 1425081600 +"%Y/%m/%d %H:%M:%S" 2>&1`;
	if (defined $test_bsd_date) {
		chomp $test_bsd_date;
	}
	if (($test_bsd_date) && ($test_bsd_date eq '2015/02/28 11:00:00')) {
		$bsd_date = 1;
	} else {
		$perl_date = 1;
	}
}

ok($timezone->timezone() =~ /^\w+(\/\w+)?$/, "\$timezone->timezone() parses correctly");
ok((grep /^Australia$/, $timezone->areas()), "Found 'Australia' in \$timezone->areas()");
ok((grep /^Melbourne$/, $timezone->locations('Australia')), "Found 'Melbourne' in \$timezone->areas('Australia')");
if (!$timezone->win32_registry()) {
ok($timezone->comment('Australia/Melbourne') eq 'Victoria', "\$timezone->comment('Australia/Melbourne') returns 'Victoria'");
}
diag(`zdump -v /usr/share/zoneinfo/$ENV{TZ} | head -n 10`);
if ($bsd_date) {
	diag("bsd test of early date:" . `TZ="Australia/Melbourne" date -r "-2172355201" +"%Y/%m/%d %H:%M:%S" 2>&1`);
} elsif ($perl_date) {
} else {
	diag("gnu test of early date:" . `TZ="Australia/Melbourne" date -d "1901/02/28 23:59:59 GMT" +"%Y/%m/%d %H:%M:%S" 2>&1`);
}

my $count = 0;
foreach my $area ($timezone->areas()) {
	foreach my $location ($timezone->locations($area)) {
		if ( $ENV{RELEASE_TESTING} ) {
		} else {
			next if ("$area/$location" ne $ENV{TZ});
		}
		$timezone->timezone("$area/$location");
		my $transition_time_index = 0;
		foreach my $transition_time ($timezone->transition_times()) {
			if (($Config{archname} !~ /^(?:amd64|x86_64)/) && ($transition_time > (2 ** 31) - 1)) {
			} elsif (($Config{archname} !~ /^(?:amd64|x86_64)/) && ($transition_time < -2 ** 31)) {
			} else {
				eval { gmtime $transition_time } or do { next };
				my $correct_date = get_external_date($area, $location, $transition_time);
				my $test_date = POSIX::strftime("%Y/%m/%d %H:%M:%S", $timezone->local_time($transition_time));
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
						ok($revert_date eq $correct_date, "Matched $revert_date to $correct_date for $area/$location for \$timezone->time_local");
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
				$test_date = POSIX::strftime("%Y/%m/%d %H:%M:%S", $timezone->local_time($transition_time));
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
						ok($revert_date eq $correct_date, "Matched $revert_date to $correct_date for $area/$location for \$timezone->time_local - 1");
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
				$test_date = POSIX::strftime("%Y/%m/%d %H:%M:%S", $timezone->local_time($transition_time));
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
						ok($revert_date eq $correct_date, "Matched $revert_date to $correct_date for $area/$location for \$timezone->time_local + 1");
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
		$formatted_date = `TZ="$area/$location" perl -MPOSIX -e 'print POSIX::strftime("%Y/%m/%d %H:%M:%S", localtime($untainted_unix_time))'`;
	} elsif ($bsd_date) {
		$formatted_date = `TZ="$area/$location" date -r $untainted_unix_time +"%Y/%m/%d %H:%M:%S"`;
	} else {
		my $gm_strftime = POSIX::strftime("%Y/%m/%d %H:%M:%S GMT", gmtime $untainted_unix_time);
		$formatted_date = `TZ="$area/$location" date -d "$gm_strftime" +"%Y/%m/%d %H:%M:%S"`;
	}
	if ($? != 0) {
		diag("external date command exited with a $? for $area/$location at " . POSIX::strftime("%Y/%m/%d %H:%M:%S GMT", gmtime $untainted_unix_time));
	}
	chomp $formatted_date;
	return $formatted_date;
}

sub guess_tz {
	my $path = '/etc/localtime';
	if (-e $path) {
		my $digest = Digest::SHA->new('sha512');
		$digest->addfile($path);
		my $localtime_digest = $digest->hexdigest();
		my $timezone = Time::Zone::Olson->new();
		my $guessed;
		foreach my $base ('/usr/share/zoneinfo', '/usr/lib/zoneinfo', $ENV{TZDIR}) {
			my $readlink;
			eval {
				if ($readlink = readlink $path) {
					if ($readlink =~ /^($base[\/\\])(\w+(?:\/[\w\-\/]+)?)$/) {
						my ($directory, $test_timezone) = ($1, $2);
						$guessed = $test_timezone;
					}
				}
			};
			if (!defined $guessed) {
				if (($base) && (-e $base)) {
					File::Find::find({	'no_chdir'	=> 1, 
								'wanted'	=> sub {
							if ($File::Find::name =~ /^($base[\/\\])(\w+(?:\/[\w\-\/]+)?)$/) {
								my ($directory, $test_timezone) = ($1, $2);
								my $digest = Digest::SHA->new('sha512');
								eval {
									$digest->addfile("$directory$test_timezone");
									my $test_digest = $digest->hexdigest();
									if ($test_digest eq $localtime_digest) {
										if ($test_timezone =~ /^(\w+)\/([\w\-\/]+)$/) {
											my ($test_area, $test_location) = ($1, $2);
											foreach my $area ($timezone->areas()) {
												if ($area eq $test_area) {
													foreach my $location ($timezone->locations($area)) {
														if ($location eq $test_location) {
															$guessed = $test_timezone;
														}
													}
												}
											}
										}
									}
								};
							}
						}}, $base);
				}
			}
		}
		if (defined $guessed) {
			return $guessed;
		}
	} elsif ($^O eq 'MSWin32') {
		require Win32API::Registry;
		my $current_timezone_registry_path = 'SYSTEM\CurrentControlSet\Control\TimeZoneInformation';
		Win32API::Registry::RegOpenKeyEx(Win32API::Registry::HKEY_LOCAL_MACHINE(), $current_timezone_registry_path, 0, Win32API::Registry::KEY_QUERY_VALUE(), my $current_timezone_registry_key) or Carp::croak("Failed to open LOCAL_MACHINE\\$current_timezone_registry_path:" . Win32API::Registry::regLastError());
		my $win32_timezone_name;
		if (Win32API::Registry::RegQueryValueEx($current_timezone_registry_key, 'TimeZoneKeyName', [], my $type, $win32_timezone_name, [])) {
		} elsif ($! == POSIX::ENOENT()) {
		} else {
			die "Failed to read LOCAL_MACHINE\\$current_timezone_registry_path\\TimeZoneKeyName:" . Win32API::Registry::regLastError();
		}
		if ($win32_timezone_name) {
		} else {
			Win32API::Registry::RegQueryValueEx($current_timezone_registry_key, 'StandardName', [], my $type, my $standard_name, []) or die "Failed to read LOCAL_MACHINE\\$current_timezone_registry_path\\StandardName:" . Win32API::Registry::regLastError();
			my ($description, $major, $minor, $build, $id) = Win32::GetOSVersion();
			my $old_timezone_registry_path;
			if ($id < 2) {
				$old_timezone_registry_path = 'SOFTWARE\Microsoft\Windows\CurrentVersion\Time Zones';
			} else {
				$old_timezone_registry_path = 'SOFTWARE\Microsoft\Windows NT\CurrentVersion\Time Zones';
			}
			Win32API::Registry::RegOpenKeyEx(Win32API::Registry::HKEY_LOCAL_MACHINE(), $old_timezone_registry_path, 0, Win32API::Registry::KEY_QUERY_VALUE() | Win32API::Registry::KEY_ENUMERATE_SUB_KEYS(), my $old_timezone_registry_key) or Carp::croak("Failed to open LOCAL_MACHINE\\$old_timezone_registry_path:" . Win32API::Registry::regLastError());
			my $enumerate_timezones = 1;
			my $old_timezone_registry_index = 0;
			while ($enumerate_timezones) {
				if (Win32API::Registry::RegEnumKeyEx($old_timezone_registry_key, $old_timezone_registry_index, my $subkey_name, [], [], [], [], [],)) {
					Win32API::Registry::RegOpenKeyEx($old_timezone_registry_key, $subkey_name, 0, Win32API::Registry::KEY_QUERY_VALUE(), my $old_timezone_specific_registry_key) or Carp::croak("Failed to open LOCAL_MACHINE\\$old_timezone_registry_path\\$subkey_name:" . Win32API::Registry::regLastError());
					Win32API::Registry::RegQueryValueEx($old_timezone_specific_registry_key, 'Std', [], my $type, my $local_language_timezone_name, []) or die "Failed to read LOCAL_MACHINE\\$current_timezone_registry_path\\$subkey_name\\Std:" . Win32API::Registry::regLastError();
					if ($local_language_timezone_name eq $standard_name) {
						$win32_timezone_name = $subkey_name
					}
				} elsif ( Win32API::Registry::regLastError() == 259 ) { # ERROR_NO_MORE_TIMES from winerror.h
					$enumerate_timezones = 0;
				} else {
					Carp::croak("Failed to read from LOCAL_MACHINE\\$old_timezone_registry_path:$EXTENDED_OS_ERROR");
				}
				    $old_timezone_registry_index += 1;
			}
			Win32API::Registry::RegCloseKey($old_timezone_registry_key) or Carp::croak("Failed to close LOCAL_MACHINE\\$old_timezone_registry_path:$EXTENDED_OS_ERROR");
		}
		Win32API::Registry::RegCloseKey($current_timezone_registry_key) or die "Failed to open LOCAL_MACHINE\\$current_timezone_registry_path:" . Win32API::Registry::regLastError();
		my %mapping = Time::Zone::Olson->win32_mapping();
		foreach my $key (sort { $a cmp $b } keys %mapping) {
			if ($mapping{$key} eq $win32_timezone_name) {
				return $key;
			}
		}
	}
	return 'Australia/Melbourne';
}

Test::More::done_testing();
