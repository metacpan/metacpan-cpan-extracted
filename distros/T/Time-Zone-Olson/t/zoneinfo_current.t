#!perl -T
use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More;
use Time::Zone::Olson();
use POSIX();
use File::Find();
use Digest::SHA();

$ENV{PATH} = '/bin:/usr/bin';
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

my $pack_q_ok = 0;
eval { my $q = pack 'q>', 2 ** 33; my $p = unpack 'q>', $q; $pack_q_ok = 1; };
diag"Results of unpack:$@";

ok(-e $timezone->directory(), "\$timezone->directory() returns the correct directory");
ok($timezone->timezone() =~ /^\w+(?:\/[\w\-\/]+)?$/, "\$timezone->timezone() parses correctly");
if ($timezone->location()) {
	ok($timezone->area() . '/' . $timezone->location() eq $timezone->timezone(), "\$timezone->area() and \$timezone->location() contain the area and location of the current timezone");
} else {
	ok($timezone->area() eq $timezone->timezone(), "\$timezone->area() and \$timezone->location() contain the area and location of the current timezone");
}
ok((grep /^Australia$/, $timezone->areas()), "Found 'Australia' in \$timezone->areas()");
ok((grep /^Melbourne$/, $timezone->locations('Australia')), "Found 'Melbourne' in \$timezone->areas('Australia')");
ok($timezone->comment('Australia/Melbourne') eq 'Victoria', "\$timezone->comment('Australia/Melbourne') returns 'Victoria'");
my $now = time;
my @correct_localtime = localtime $now;
my @test_localtime = $timezone->local_time($now);
my $matched = 1;
foreach my $index (0 .. (( scalar @correct_localtime )- 1)) {
	if ($correct_localtime[$index] ne $test_localtime[$index]) {
		$matched = 0;
	}
}
foreach my $index (0 .. (( scalar @test_localtime )- 1)) {
	if ($correct_localtime[$index] ne $test_localtime[$index]) {
		$matched = 0;
	}
}
ok($matched, "Matched wantarray localtime");
my $melbourne_offset;
my $melbourne_date;
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
ok((defined $melbourne_offset) && (($melbourne_offset == 600) or ($melbourne_offset == 660)), "Correctly returned the offset for Melbourne/Australia is either 600 or 660 minutes");

$timezone->offset($melbourne_offset);
my $test_date = $timezone->local_time($now);
ok($test_date eq $melbourne_date, "Matched $test_date to $melbourne_date for when manually setting offset to $melbourne_offset minutes");
my @local_time = $timezone->local_time($now);
my $revert_time = $timezone->time_local(@local_time);
ok($revert_time <= $now, "\$timezone->time_local(\$timezone->local_time(\$now)) == \$now when manually setting offset to $melbourne_offset minutes");

$timezone = Time::Zone::Olson->new({ 'offset' => $melbourne_offset });
$test_date = $timezone->local_time($now);
ok($test_date eq $melbourne_date, "Matched $test_date to $melbourne_date for when manually setting offset to $melbourne_offset minutes");
@local_time = $timezone->local_time($now);
$revert_time = $timezone->time_local(@local_time);
ok($revert_time <= $now, "\$timezone->time_local(\$timezone->local_time(\$now)) == \$now when manually setting offset to $melbourne_offset minutes");

$timezone->timezone("Australia/Melbourne");
ok($timezone->equiv("Australia/Hobart") && !$timezone->equiv("Australia/Perth") && !$timezone->equiv("Australia/Hobart", 0), "Successfully compared Melbourne to Perth and Hobart timezones");
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

