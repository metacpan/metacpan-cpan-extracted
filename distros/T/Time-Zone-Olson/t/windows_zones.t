#! /usr/bin/perl -wT

use strict;
use warnings;
use File::Temp();
use Fcntl();
use XML::LibXML();
use Test::More;
use Time::Zone::Olson();
use LWP::UserAgent();
use HTTP::Request();
use Encode();
use English qw( -no_match_vars );

my $ua = LWP::UserAgent->new();
$ua->env_proxy();
$ua->timeout(10);
$ua->agent('CPAN Testing https://metacpan.org/pod/Time::Zone::Olson ');

my $url = 'https://raw.githubusercontent.com/unicode-org/cldr/master/common/supplemental/windowsZones.xml';
diag("Checking $url");
my $request = HTTP::Request->new(GET => $url);
ok(1, "Initialised test");

my $response;
eval {
	$response = $ua->request($request);
};
my $windows_handle;
if (defined $response && $response->is_success()) {
	$windows_handle = File::Temp::tempfile('cpan_tester_time_zone_olson_win32_XXXXXXXXXXX') or die "Failed to open temporary file for writing:$EXTENDED_OS_ERROR";
	binmode $windows_handle;

	my $content = Encode::decode('UTF-8', $response->decoded_content());
	$content =~ s/[^[:ascii:]]//smxg;
	$windows_handle->print($content);
	seek $windows_handle, 0, Fcntl::SEEK_SET() or die "Failed to seek to start of temporary file:$!";

	my %olson_to_win32_mapping;
	my $dom = XML::LibXML->load_xml(IO => $windows_handle);
	my $supplementary_data = $dom->documentElement();
	foreach my $windows_zone ( $supplementary_data->getChildrenByTagName('windowsZones') ) {
		foreach my $map_time_zones( $windows_zone->getChildrenByTagName('mapTimezones') ) {
			foreach my $map_zone ( $map_time_zones->getChildrenByTagName('mapZone') ) {
				foreach my $name (split q[ ], $map_zone->getAttribute( 'type' )) {
					$olson_to_win32_mapping{$name} = $map_zone->getAttribute('other');
				}
			}
		}
	}
	my $todo;
	if ($^O eq 'MSWin32') {
		require Win32;
		my $display_name = Win32::GetOSDisplayName();
		my $os_name = Win32::GetOSName();
		my ($description, $major, $minor, $build, $id) = Win32::GetOSVersion();
		if ($major < 10) { # below Windows 10
			$todo = "$os_name does not have all timezones";
		}
		diag("Current version of Windows is $major - $display_name ($os_name)");
	}
	local $TODO = $todo;
	my %module_mapping = Time::Zone::Olson->win32_mapping();
	foreach my $olson_time_zone (sort { $a cmp $b } keys %olson_to_win32_mapping) {
		ok($module_mapping{$olson_time_zone}, "$olson_time_zone can be found in Time::Zone::Olson->win32_mapping()");
	}
} elsif (defined $response) {
	diag "Failed to download $url:" . $response->status_line();
} else {
	diag "Timed out on $url:$EVAL_ERROR";
}
if ( $OSNAME eq 'MSWin32' ) {
	my $timezone_database_registry_path = 'SOFTWARE\\Microsoft\\Windows NT\\CurrentVersion\\Time Zones';
        Win32API::Registry::RegOpenKeyEx(Win32API::Registry::HKEY_LOCAL_MACHINE(), $timezone_database_registry_path, 0, Win32API::Registry::KEY_QUERY_VALUE() | Win32API::Registry::KEY_ENUMERATE_SUB_KEYS(), my $timezone_database_subkey) or Carp::croak("Failed to open LOCAL_MACHINE\\$timezone_database_registry_path:$EXTENDED_OS_ERROR");
	my $enumerate_timezones = 1;
	my $timezone_index      = 0;
	my %local_windows_timezones;
	while ($enumerate_timezones) {
		if (Win32API::Registry::RegEnumKeyEx($timezone_database_subkey, $timezone_index, my $buffer, [], [], [], [], [])) {
			$local_windows_timezones{$buffer} = 1;
		} elsif ( Win32API::Registry::regLastError() == 259 ) { # ERROR_NO_MORE_TIMES from winerror.h
			$enumerate_timezones = 0;
		} else {
			Carp::croak("Failed to read from LOCAL_MACHINE\\$timezone_database_registry_path:$EXTENDED_OS_ERROR");
		}
		$timezone_index += 1;
	}
	Win32API::Registry::RegCloseKey($timezone_database_subkey) or Carp::croak("Failed to close LOCAL_MACHINE\\$timezone_database_registry_path:$EXTENDED_OS_ERROR");
	my %win32_mapping = Time::Zone::Olson->win32_mapping();
	foreach my $timezone (sort { $a cmp $b } keys %local_windows_timezones) {
		my $found;
		foreach my $olson_timezone (sort { $a cmp $b } keys %win32_mapping) {
			if ($win32_mapping{$olson_timezone} eq $timezone) {
				$found = 1;
			}
		}
		TODO: {
			local $TODO = "Known missing case" if ($timezone =~ /^(?:
											(?:
												Armenian|
												Kamchatka|
												Magallanes|
												Mexico|
												Mid\-Atlantic|
												Qyzylorda|
												Sao[ ]Tome|
												Saratov|
												Sudan|
												South[ ]Sudan|
												Volgograd|
												Yukon
											)[ ]Standard[ ]Time(?:[ ]2)?|
											UTC[+]13
										)$/smx);
			ok($found, "Successfully found Win32 timezone $timezone in olson tz mapping");
		}
		if (!$found) {
			diag("Unable to locate Win32 timezone $timezone in the olson tz mapping");
		}
	}
}
Test::More::done_testing();
