#!/usr/bin/env perl

# Sanity test of the code, makes no connection to the API

use strict;
use warnings;

use Test::Most tests => 5;
use Test::MockModule;
use LWP::UserAgent;

BEGIN { use_ok('TimeZone::TimeZoneDB') }

# Mock the LWP::UserAgent to avoid actual API calls
my $mock_ua = Test::MockModule->new('LWP::UserAgent');
$mock_ua->mock(get => sub {
	my ($self, $url) = @_;

	# Simulated API response
	my $response = HTTP::Response->new(200);
	$response->content('{"status":"OK","zoneName":"America/New_York"}');
	return $response;
});

# Test object creation
subtest 'Object Creation' => sub {
	my $tzdb = TimeZone::TimeZoneDB->new(key => 'dummy_key');
	ok($tzdb, 'Object created successfully');
	isa_ok($tzdb, 'TimeZone::TimeZoneDB', 'Object is of correct class');
};

# Test missing API key
subtest 'Missing API Key' => sub {
	dies_ok { my $tzdb = TimeZone::TimeZoneDB->new() } 'Creation fails without an API key';
};

# Test get_time_zone method with valid input
subtest 'Get Time Zone' => sub {
	my $tzdb = TimeZone::TimeZoneDB->new(key => 'dummy_key', ua => LWP::UserAgent->new());
	my $result = $tzdb->get_time_zone({ latitude => 40.7128, longitude => -74.0060 });

	ok($result, 'Valid API response received');
	is($result->{'zoneName'}, 'America/New_York', 'Correct timezone returned');
};

# Test get_time_zone with missing parameters
subtest 'Get Time Zone - Missing Parameters' => sub {
	my $tzdb = TimeZone::TimeZoneDB->new(key => 'dummy_key', ua => LWP::UserAgent->new());
	throws_ok {
		$tzdb->get_time_zone();
	} qr/Required parameter/, 'Dies when missing parameters';
};
