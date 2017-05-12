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

$ENV{TZ} ||= guess_tz();

diag("TZ environment variable is $ENV{TZ}");

my $timezone = Time::Zone::Olson->new();
ok($timezone, "Time::Zone::Olson->new() generates an object");

if ($timezone->location()) {
	$ENV{TZ} = $timezone->area() . '/' . $timezone->location();
} else {
	$ENV{TZ} = $timezone->area();
}
diag("TZ environment variable is untainted as $ENV{TZ}");

my $perl_date = 0;
my $bsd_date = 0;
my $test_gnu_date = `TZ="Australia/Melbourne" date -d "2015/02/28 11:00:00" +"%Y/%m/%d %H:%M:%S" 2>&1`;
chomp $test_gnu_date;
if (($test_gnu_date) && ($test_gnu_date eq '2015/02/28 11:00:00')) {
} else {
	my $test_bsd_date = `TZ="Australia/Melbourne" date -r 1425081600 +"%Y/%m/%d %H:%M:%S" 2>&1`;
	chomp $test_bsd_date;
	if (($test_bsd_date) && ($test_bsd_date eq '2015/02/28 11:00:00')) {
		$bsd_date = 1;
	} else {
		$perl_date = 1;
	}
}

ok($timezone->timezone() =~ /^\w+(\/\w+)?$/, "\$timezone->timezone() parses correctly");
ok((grep /^Australia$/, $timezone->areas()), "Found 'Australia' in \$timezone->areas()");
ok((grep /^Melbourne$/, $timezone->locations('Australia')), "Found 'Melbourne' in \$timezone->areas('Australia')");
ok($timezone->comment('Australia/Melbourne') eq 'Victoria', "\$timezone->comment('Australia/Melbourne') returns 'Victoria'");
diag(`zdump -v /usr/share/zoneinfo/$ENV{TZ} | head -n 10`);
if ($bsd_date) {
	diag("bsd test of early date:" . `TZ="Australia/Melbourne" date -r "-2172355201" +"%Y/%m/%d %H:%M:%S" 2>&1`);
} elsif ($perl_date) {
} else {
	diag("gnu test of early date:" . `TZ="Australia/Melbourne" date -d "1901/02/28 23:59:59 GMT" +"%Y/%m/%d %H:%M:%S" 2>&1`);
}

my $count = 0;
my $time_local_has_negative_problems;
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
			} elsif ($^O eq 'MSWin32') { # Win32 platforms will not have historical time records
			} else {
				eval { gmtime $transition_time } or do { next };
				my $correct_date = get_external_date($area, $location, $transition_time);
				my $test_date = POSIX::strftime("%Y/%m/%d %H:%M:%S", $timezone->local_time($transition_time));
				SKIP: {
					if ($correct_date) {
						ok($test_date eq $correct_date, "Matched $test_date to $correct_date for $area/$location for \$timezone->local_time");
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
	if ($perl_date) {
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
	}
	return 'Australia/Melbourne';
}

Test::More::done_testing();
