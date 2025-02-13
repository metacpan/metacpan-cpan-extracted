#!/usr/bin/env perl

# Test rate limiting

use strict;
use warnings;
use CHI;
use Geo::Location::Point;
use Time::HiRes qw(time);
use Test::Most tests => 5;

BEGIN { use_ok('TimeZone::TimeZoneDB') }

RATE_LIMIT: {
	# --- Create a custom LWP::UserAgent for testing ---
	{
		package MyTestUA;
		use parent 'LWP::UserAgent';
		use HTTP::Response;

		# Global variables to count requests and record request times
		our $REQUEST_COUNT = 0;
		our @REQUEST_TIMES;

		sub get {
			my ($self, $url) = @_;
			push @REQUEST_TIMES, time();
			$REQUEST_COUNT++;

			# Return a dummy successful JSON response. The JSON is a simplified
			# version of what the TimeZoneDB API might return.
			my $content = '{"zoneName": "America/New_York", "status": "OK"}';
			return HTTP::Response->new(200, 'OK', [], $content);
		}
	}

	# Set a short minimum interval for testing purposes (e.g. 1 second)
	# But don't test for less than a second without changing the test timer to track microseconds
	my $min_interval = 1;

	# Create our custom user agent
	my $ua = MyTestUA->new();

	# Create an in-memory cache using CHI
	my $cache = CHI->new(
		driver => 'Memory',
		global => 1,
		expires_in => '1 hour',
	);

	# Instantiate with our custom UA and min_interval
	my $tzdb = TimeZone::TimeZoneDB->new(
		key => 'xyzzy',
		min_interval => $min_interval,
		ua => $ua,
		cache => $cache
	);

	my $leesburg = Geo::Location::Point->new({ latitude => 39.1155, longitude => -77.5644 });
	# Find two timezones
	my $tz = $tzdb->get_time_zone($leesburg)->{'zoneName'};
	my $ramsgate = Geo::Location::Point->new({ latitude => 51.34, longitude => 1.42 });
	$tz = $tzdb->get_time_zone($ramsgate)->{'zoneName'};

	# Verify that the rate limiting was enforced by comparing the timestamps of
	# the two API calls. There should now be two entries in @MyTestUA::REQUEST_TIMES.
	my $num_requests = scalar @MyTestUA::REQUEST_TIMES;
	ok($num_requests >= 2, 'At least two API requests have been made');
	cmp_ok($num_requests, '==', $MyTestUA::REQUEST_COUNT);

	ok($cache->get('tz:51.34:1.42'));

	if($num_requests >= 2) {
		my $elapsed = $MyTestUA::REQUEST_TIMES[1] - $MyTestUA::REQUEST_TIMES[0];
		cmp_ok($elapsed, '>=', $min_interval, "Rate limiting enforced: elapsed time >= $min_interval sec");
	}
}
