#!/usr/bin/env perl

# Sanity test of the code, makes no connection to the API

use strict;
use warnings;

use lib "$ENV{HOME}/src/njh/Test-Mockingbird/lib";

use HTTP::Response;
use Test::Most tests => 5;
use Test::Mockingbird;
use LWP::UserAgent;

BEGIN { use_ok('TimeZone::TimeZoneDB') }

# Mock LWP::UserAgent::get for the whole file to avoid real HTTP calls.
# The mock returns a canned 200 OK response with a known JSON body.
mock 'LWP::UserAgent::get' => sub {
	my $response = HTTP::Response->new(200, 'OK');
	$response->content('{"status":"OK","zoneName":"America/New_York"}');
	return $response;
};

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
	my $tzdb   = TimeZone::TimeZoneDB->new(key => 'dummy_key', ua => LWP::UserAgent->new());
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

# Restore the LWP::UserAgent::get mock installed at the top of the file
restore_all();
