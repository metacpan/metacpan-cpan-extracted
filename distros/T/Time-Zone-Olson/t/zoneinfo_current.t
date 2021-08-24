#!perl -T
use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More;
use Time::Zone::Olson();
use POSIX();
use English qw( -no_match_vars );

if ($^O eq 'MSWin32') {
} else {
	$ENV{PATH} = '/bin:/usr/bin';
}
delete @ENV{'IFS', 'CDPATH', 'ENV', 'BASH_ENV'};

if ($ENV{TZ}) {
	diag("TZ environment variable is $ENV{TZ}");
}
my $timezone = Time::Zone::Olson->new();
ok($timezone, "Time::Zone::Olson->new() generates an object");

if ($timezone->location()) {
	$ENV{TZ} = $timezone->area() . '/' . $timezone->location();
} elsif ($timezone->area()) {
	$ENV{TZ} = $timezone->area();
}
if (defined $ENV{TZ}) {
	diag("Determined timezone is $ENV{TZ}");
} else {
	diag("Timezone did not parse into area/location:" . $timezone->timezone());
}
if (defined $ENV{TZDIR}) {
	diag("TZDIR has been set to $ENV{TZDIR}");
} else {
	diag("TZDIR has not been set");
}

my $perl_date = 0;
my $bsd_date = 0;

if ($^O eq 'MSWin32') {
	diag "$^O means we need to use the SystemTimeToTzSpecificLocalTime system call as the definitive source of truth for timezone calculations";
} elsif ($^O eq 'solaris') {
	diag "$^O does not have a useful date binary.";
	$perl_date = 1;
} else {
	my $test_gnu_date = `TZ="Australia/Melbourne" date -d "2015/02/28 11:00:00" +"%Y/%m/%d %H:%M:%S" 2>&1`;
	chomp $test_gnu_date;
	diag "Output of gnu date command:$test_gnu_date";
	if (($test_gnu_date) && ($test_gnu_date eq '2015/02/28 11:00:00')) {
	} else {
		my $test_bsd_date = `TZ="Australia/Melbourne" date -r 1425081600 +"%Y/%m/%d %H:%M:%S" 2>&1`;
		chomp $test_bsd_date;
		diag "Output of bsd date command:$test_bsd_date";
		if (($test_bsd_date) && ($test_bsd_date eq '2015/02/28 11:00:00')) {
			$bsd_date = 1;
		} else {
			$perl_date = 1;
		}
	}
}

my $pack_q_ok = 0;
eval { my $q = pack 'q>', 2 ** 33; my $p = unpack 'q>', $q; $pack_q_ok = 1; };
diag"Results of unpack:$@";

if ($^O eq 'MSWin32') {
	ok(!defined $timezone->directory(), "\$timezone->directory() is not defined for $^O");
} else {
	ok(-e $timezone->directory(), "\$timezone->directory() returns the correct directory");
}
if (!$timezone->timezone()) {
	$timezone->timezone('UTC');
	diag("$^O does not have a default timezone, setting to " . $timezone->timezone());
}
diag("Local timezone has been determined to be " . $timezone->timezone() );
ok($timezone->timezone() =~ /^\w+(?:\/[\w\-\/]+)?$/, "\$timezone->timezone() parses correctly");
if ($timezone->location()) {
	ok($timezone->area() . '/' . $timezone->location() eq $timezone->timezone(), "\$timezone->area() and \$timezone->location() contain the area and location of the current timezone");
} else {
	ok($timezone->area() eq $timezone->timezone(), "\$timezone->area() and \$timezone->location() contain the area and location of the current timezone");
}
ok((grep /^Australia$/, $timezone->areas()), "Found 'Australia' in \$timezone->areas()");
ok((grep /^Melbourne$/, $timezone->locations('Australia')), "Found 'Melbourne' in \$timezone->areas('Australia')");
if ($^O eq 'MSWin32') {
	diag("$^O comment for Australia/Melbourne is '" . Encode::encode('UTF-8', $timezone->comment('Australia/Melbourne'), 1) . "'");
	ok($timezone->comment('Australia/Melbourne') =~ /^[(](?:GMT|UTC)[+]10:00[)][ ]/smx, "\$timezone->comment('Australia/Melbourne') contains //^[(]GMT[+]10:00[)][ ]");
} else {
	ok($timezone->comment('Australia/Melbourne') =~ /Victoria/smx, "\$timezone->comment('Australia/Melbourne') contains /Victoria/");
}
my $now = time;
my @correct_localtime = localtime $now;
my @test_localtime = $timezone->local_time($now);
my $matched = 1;
foreach my $index (0 .. (( scalar @correct_localtime )- 1)) {
	if ($correct_localtime[$index] eq $test_localtime[$index]) {
	} else {
		diag("Missed wantarray location (1) test for $^O on index $index ('$correct_localtime[$index]' eq '$test_localtime[$index]')");
		$matched = 0;
	}
}
foreach my $index (0 .. (( scalar @test_localtime )- 1)) {
	if ($correct_localtime[$index] eq $test_localtime[$index]) {
	} else {
		diag("Missed wantarray location (2) test for $^O on index $index ('$correct_localtime[$index]' eq '$test_localtime[$index]')");
		$matched = 0;
	}
}

ok($matched, "Matched wantarray localtime");
if (!$matched) {
	diag("Seconds since UNIX epoch is:$now");
	diag("Time::Zone::Olson produces:" . join ', ', @test_localtime);
	diag("perl localtime produces   :" . join ', ', @correct_localtime);
	diag(`ls -la /etc/localtime`);
	my $current_timezone = $timezone->timezone();
	my $directory = $timezone->directory();
	diag("Permissions of $directory/$current_timezone is " . `ls -la $directory/$current_timezone`);
	diag("Content of $directory/$current_timezone is " . `cat $directory/$current_timezone | base64`);
}

my $melbourne_offset;
my $melbourne_date;
DATE: {
	my $todo;
	if ($perl_date) {
		$todo = "perl does not always agree with date(1)";
	}
	local $TODO = $todo;
	foreach my $area ($timezone->areas()) {
		foreach my $location ($timezone->locations($area)) {
			my $correct_date = get_external_date($area, $location, $now);
			$timezone->timezone("$area/$location");
			if ($timezone->timezone() eq 'Australia/Melbourne') {
				$melbourne_offset = $timezone->local_offset($now);
				$melbourne_date = $timezone->local_time($now);
			}
			my $test_date = POSIX::strftime('%Y/%m/%d %H:%M:%S', $timezone->local_time($now));
			ok($test_date eq $correct_date, "Matched $test_date to $correct_date for $area/$location");
			my @local_time = $timezone->local_time($now);
			my $revert_time = $timezone->time_local(@local_time);
			ok($revert_time <= $now, "\$timezone->time_local(\$timezone->local_time(\$now)) <= \$now where $revert_time = $now with a difference of " . ($revert_time - $now) . " for $area/$location"); 
			my @leap_seconds = $timezone->leap_seconds();
			die "Leap seconds found in $area/$location" if (scalar @leap_seconds);
		}
	}
}
ok((defined $melbourne_offset) && (($melbourne_offset == 600) or ($melbourne_offset == 660)), "Correctly returned the offset for Melbourne/Australia is either 600 or 660 minutes");

$timezone->offset($melbourne_offset);
my $test_date = $timezone->local_time($now);
ok($test_date eq $melbourne_date, "Matched $test_date to $melbourne_date for when manually setting offset to $melbourne_offset minutes");
my @local_time = $timezone->local_time($now);
my $revert_time = $timezone->time_local(@local_time);
ok($revert_time <= $now, "\$timezone->time_local(\$timezone->local_time(\$now)) == \$now when manually setting offset to $melbourne_offset minutes");

$timezone = Time::Zone::Olson->new( 'offset' => $melbourne_offset );
$test_date = $timezone->local_time($now);
ok($test_date eq $melbourne_date, "Matched $test_date to $melbourne_date for when manually setting offset to $melbourne_offset minutes");
@local_time = $timezone->local_time($now);
$revert_time = $timezone->time_local(@local_time);
ok($revert_time <= $now, "\$timezone->time_local(\$timezone->local_time(\$now)) == \$now when manually setting offset to $melbourne_offset minutes");

$timezone->timezone("Australia/Melbourne");

if (($^O eq 'linux') || ($^O =~ /bsd/)) {
	ok($timezone->equiv("Australia/Hobart") && !$timezone->equiv("Australia/Perth") && !$timezone->equiv("Australia/Hobart", 0), "Successfully compared Melbourne to Perth and Hobart timezones");
} else {
	if (!$timezone->equiv("Australia/Hobart")) {
		diag("$^O does not agree that Melbourne and Hobart time are the same from now on");
	}
	ok(!$timezone->equiv("Australia/Perth"), "Successfully compared Melbourne to Perth timezones");
	if ($timezone->equiv("Australia/Hobart", 0)) {
		diag("$^O does not agree that Melbourne and Hobart time have NOT been the same since the UNIX epoch");
	}
}
if (!$matched) {
	my @test_localtime = $timezone->local_time($now);
	diag("Time::Zone::Olson produces for " . $timezone->timezone() . ":" . join ', ', @test_localtime);
	if ($^O eq 'MSWin32') {
	} elsif ($^O eq 'solaris') {
		diag("date returns " . `date`);
	}
}
Test::More::done_testing();

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
		$formatted_date = `TZ="$area/$location" perl -MPOSIX -e 'print POSIX::strftime(q[%Y/%m/%d %H:%M:%S], localtime($untainted_unix_time))'`;
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

